'''
AWS common libs

import this into each runner submodule 

Performs functions that are common to all runner use cases and products.
Product specific functions should be contained with the runner submodules

'''
# TODO: refactor all functions to use boto connector instead of making 
# direct aws cli calls. Still some remaining as of 8/18/2016
# *** CODE NEEDS TO BE CLEANED UP IN THIS MODULE. MANY FUNCTIONS ARE NOT USED WITH NEW
# CODE FOR CONDUCTOR

from __future__ import absolute_import

from common.utility import Logger
import simplejson as json
import yaml
import os, sys
import random
import inspect
import time
from datetime import datetime, timedelta
import ast
import subprocess
import collections

from boto import ec2
from boto.ec2.elb import HealthCheck

logger = Logger()

debug = False


def remove_network_interfaces_from_security_group(awsconnector=None, secgroup=None, retry=10, wait=2):
  '''
  input: 
  awsconnector - valid boto aws connector
  secgroup - valid group name
  retry and wait - optional

  return: True|False, [] list of removed interfaces

  '''
  if not awsconnector:
    logger.log('must pass valid awsconnector', logger.state.error)
    return False, []
  
  removed = True
  removed_interfaces = []

  interfaces = awsconnector.get_all_network_interfaces()

  if debug:
    logger.log('retry={0} wait={1}'.format(retry, wait))

  def _delete_interface(conn, interface_id):
    logger.log('attempt removing interface {0}'.format(interface_id))
    try:
      ret = conn.delete_network_interface(interface_id, dry_run=False)
    except:
      logger.log('Failed to execute delete_network_interface()', logger.state.error)
      return False, []

    return True, []

  for interface in interfaces:
    if interface.groups:
      for secgrp in interface.groups:
        if secgrp.name == secgroup:
          # CHECK IF INTERFACE IS ATTACHED TO ANYTHING
          if interface.attachment:
            removed = False
            logger.log('interface attachment: {0}'.format(interface.attachment.id))
            logger.log('interface: {0}'.format(interface.id))
            try:
              if awsconnector.detach_network_interface(interface.attachment.id, force=True, dry_run=False):
                logger.log('successfully detached: {0}'.format(interface.attachment.id))
              else:
                logger.log('Failed to detach network attachment {0}'.format(interface.attachment.id), logger.state.error)
            except Exception as e:
              logger.log('Failed to detach network interface.\nHINT: verify the region you passed matches the region of the NE you are trying to destroy.', logger.state.error)
              return False, []
         
          # NOW ATTEMPT DELETE
          ctr = retry

          while ctr > 0:
             if _delete_interface(awsconnector, interface.id):
               break
             else:
               ctr-=1
               time.sleep(wait)
                   
          if ctr:
            removed = True
            logger.log('successfully deleted interface: {0}'.format(interface.id))
            removed_interfaces.append(interface.id)
          else:
            logger.log('delete network interface {0} may have timed out, try waiting longer...'.format(interface.id), logger.state.warning)

  if removed:
    return True, removed_interfaces
 
  return False, removed_interfaces


def unregister_elb_instances(region=None, name=None, instances=[]):
  '''
  required inputs:
  region - aws region
  name - elb name to delete
  instances - list of aws instance id's
  '''
  import boto.ec2.elb

  if not name or not region:
    return False

  elb_conn = boto.ec2.elb.connect_to_region(region)
 
  if instances and isinstance(instances, list):
    try:
      elb_conn.deregister_instances(instance_ids)

    except Exception as e:
      logger.log('Failed to deregister instance from elb, {0}'.format(str(e.message)), logger.state.error)
      return False

  return True

def get_aws_load_balancers(region=None, names=[]):
  '''
  required inputs:

  region - region of the elbs

  optional:
  
  names - List of lb names to filter on
 
  return:
    True|False, List elbs
  '''

  import boto.ec2.elb

  lbs = []
  if not region:
    logger.log('valid aws region is required', logger.state.error) 
    return False, lbs

  elb_conn = boto.ec2.elb.connect_to_region(region)
 
  try:
    if names:
      lbs = elb_conn.get_all_load_balancers(load_balancer_names=names)
    else:
      lbs = elb_conn.get_all_load_balancers()

  except Exception as e:
    logger.log('Failed to get aws elbs, {0}'.format(str(e.message)), logger.state.error)
    return False, lbs

  if debug:
    logger.log('{0} {1}'.format(lbs, type(lbs)))

    for lb in lbs:
      logger.log('{0} {1}'.format(lb, type(lb)))
      x = str(lb).split(':')[1]
      logger.log('..... {0}'.format(x))

  if lbs:
    return True, lbs
  return False, lbs


def delete_aws_load_balancer(region=None, name=None):
  '''
  required inputs:

  region - region where the elb lives in aws
  name - name of elb to remove
  '''

  import boto.ec2.elb

  if not name or not region:
    logger.log('name and region are required params', logger.state.error)
    return False

  elb_conn = boto.ec2.elb.connect_to_region(region)
 
  try:
    lb = elb_conn.delete_load_balancer(name)

  except Exception as e:
    logger.log('Failed to delete aws elb, {0}'.format(str(e.message)), logger.state.error)
    return False

  logger.log(lb)
  logger.log('Removed elb {0}'.format(name))

  return True

def _elb_exists(name, region):
  '''
  input:
    name - string elb name
    region - aws region
  return:
    True|False
  '''
  if not name or not region:
    return False

  result, elbs = get_aws_load_balancers(region, names=name.split())

  print 'debug: return from checking existence of elbs', result, elbs

  if elbs:
    return True
  else:
    return False

def convert(data):
  if isinstance(data, basestring):
      return str(data)
  elif isinstance(data, collections.Mapping):
      return dict(map(convert, data.iteritems()))
  elif isinstance(data, collections.Iterable):
      return type(data)(map(convert, data))
  else:
      return data

def create_elastic_load_balancer(region=None, \
                             name=None, \
                             zones=None, \
                             subnets=[], \
                             security_groups=None, \
                             ports=None, \
                             hc={}, \
                             instances=[],\
                             scheme=None):
  '''
  required inputs:

  name - string name of elb (used to verify existance as well)

  zones - list of aws zones example ['us-east-1a', 'us-east-1b']
          NOTE: there should always only be one zone in list

  ports - list of port tuple [(port,forward port,protocol)]

  subnets - optional. can only use either zones or subnets not both.
            must be a list of string of subnets

  security_groups - options. list of security groups to add to lb

  defaults will be set if hc is not passed in:

  hc - health check dictionary 
       example: {interval: 10, timeout: 5, healthy_threshold: 2, unhealthy_threshold: 4, target: /health}

  instances - list of aws instance id's
  
  scheme - optional. specify 'internal' for private, leave None for internet-facing

  '''
  import boto.ec2.elb

  if not name or not region:
    logger.log('name and region are required params', logger.state.error) 
    return False, None

  lb = None

  conn = boto.ec2.elb.connect_to_region(region)

  # remove encoding from instances list
  _instances = convert(instances)


  if not _elb_exists(name, region):

    logger.log('elb {0} does NOT exist'.format(name))

    _ports = None  
    port_tuple = []

    logger.log('attempt create elb {0}'.format(name))

    if not ports or not isinstance(ports, list):

      logger.log('Using default ports...')

      src_port = 80
      if hc and 'forwarding_port' in hc:
        dest_port = int(hc['forwarding_port'])
      else:
        dest_port = 8080
      protocol = 'http'
      _ports = (src_port, dest_port, protocol)  
      port_tuple.append(_ports)

    else:
      if not isinstance(ports[0], tuple):
        logger.log('Passed an invalid type for ports, must be tuple [(port,forward,protocol)]', logger.state.error)
        return False, None
      else:
        port_tuple = ports

    # SET DEFAULTS JUST IN CASE
    if not 'interval' in hc:
      hc['interval'] = 10
    if not 'timeout' in hc:
      hc['timeout'] = 5
    if not 'healthy_threshold' in hc:
      hc['healthy_threshold'] = 2
    if not 'unhealthy_threshold' in hc:
      hc['unhealthy_threshold'] = 4
    if not 'target' in hc:
      hc['target'] = '/health'
    if not 'forwarding_port' in hc:
      hc['forwarding_port'] = '8080'

    logger.log('Healthcheck config:\n{0}'.format(hc))

    sec_grps = None
    if security_groups and isinstance(security_groups, list):
      sec_grps = security_groups

    logger.log('creating load balancer: {0}'.format(name))
    try:
      if subnets:
        if scheme:
          lb = conn.create_load_balancer(name, None, port_tuple, subnets=subnets, security_groups=sec_grps, scheme=scheme)
        else:
          lb = conn.create_load_balancer(name, None, port_tuple, subnets=subnets, security_groups=sec_grps)
      else:
        if scheme:
          lb = conn.create_load_balancer(name, zones, port_tuple, security_groups=sec_grps, scheme=scheme)
        else:
          lb = conn.create_load_balancer(name, zones, port_tuple, security_groups=sec_grps)

      # CREATE THE HEALTHCHECK (REQUIRED)
      healthcheck = HealthCheck(interval=hc['interval'],
                               healthy_threshold=hc['healthy_threshold'],
                               unhealthy_threshold=hc['unhealthy_threshold'],
                               target='HTTP:{0}{1}'.format(hc['forwarding_port'], hc['target']))
  
      print 'DEBUG: healthcheck', healthcheck

      lb.configure_health_check(healthcheck)

    except Exception as e:
      logger.log('Failed to create aws elb\n{0}\n'.format(e), logger.state.error) 
      return False, None
  
  else:
  
    logger.log('elb {0} exists'.format(name))
 
    # get existing elb handle
    lbs = conn.get_all_load_balancers(load_balancer_names=name.split())
    lb = lbs[0]    
    
  logger.log('using elb: {0}'.format(lb.dns_name))
  logger.log('adding instances {0}'.format(_instances))

  # ADD INSTANCES
  if instances and isinstance(instances, list):
    try:
      logger.log('registering instances....')
      lb.register_instances(instances)    
    except Exception as e:
      logger.log('Failed to attach instances {0} to elb {1}\n{2}'.format(instances, lb.dns_name, e), logger.state.error)
      return False, None

  logger.log(lb.dns_name)

  return True, lb.dns_name


def create_tag(awsconnector=None, ids=[], tags={}):
  '''
  Creates or updates tag for aws instances
  input: valid boto aws connector
         valid aws instance id list
         dict of tags

  return: True|False
  '''

  if not awsconnector:
    return False

  if not isinstance(ids, list) or not isinstance(tags, dict):
    logger.log('bad parameter type', logger.state.error)
    return False

  results = False
  results = awsconnector.create_tags(ids, tags, dry_run=False)
  
  return results


def create_instance_tag(awsconnector=None, ids=[], tags={}):
  '''
  Creates or updates tag for aws instances
  input: valid boto aws connector
         valid aws instance id list
         dict of tags

  return: True|False
  '''

  if not awsconnector:
    return False

  if not isinstance(ids, list) or not isinstance(tags, dict):
    logger.log('bad parameter type in create_instance_tag()', logger.state.error)
    return False

  results = False
  results = awsconnector.create_tags(ids, tags, dry_run=False)
  
  return results


def get_instance_status(awsconnector=None, id=None):
  '''
  input: valid boto aws connector
         valid aws instance id

  return: string STATUS
  '''
  if debug:
    logger.log('passed id = {0}'.format(id))

  instances = awsconnector.get_only_instances()
  for instance in instances:
    if instance.id == id:
      if debug:   
        logger.log('match ids: {0} {1}'.format(instance.id, id))
        logger.log('{0} {1}'.format(instance.tags['Name'] , 'STATUS={0}'.format(instance.state)))

      return instance.state


def get_aws_instances(awsconnector=None):
  '''
  input: valid boto aws connector

  return: True|False , []
          list of all instances for a given aws region
          use i.__dict__ for all items in list when iterating
  '''
  if not awsconnector:
    logger.log('Valid aws boto connector must be specified in awsconnector param', logger.state.error)
    return False, []

  #print awsconnector, type(awsconnector)

  try:
    reservations = awsconnector.get_all_instances()
  except Exception as e:
    logger.log('Failed to lookup instances in aws for region, may be none available', logger.state.warning)
    logger.log(e)
    return False, []

  if debug:
    logger.log('aws reservations:\{0}'.format(reservations))

  instances = [i for r in reservations for i in r.instances]
  if instances:
    return True, instances
  
  return False, []

def associate_elasticip(awsconnector=None, eip_id=None, instance_id=None):
  '''
  input: 
  awsconnector - valid boto aws connector
  eip_id - elastic ip allocation id
  instance_id - valid ec2 instance id

  return: True|False 
  '''
  if not awsconnector or not eip_id or not instance_id:
    logger.log('awsconnector, eip_id, instance_id are all required params', logger.state.error)
    return False

  try:
    results = awsconnector.associate_address(instance_id=instance_id, \
                                               allocation_id=eip_id)
  except Exception as e:
    logger.log('Failed to associate address: {0}'.format(e), logger.state.error)
    return False

  return True

def allocate_elasticip(awsconnector=None, domain='vpc'):
  '''
  input: 
  awsconnector - valid boto aws connector
  domain - standard | vpc

  return: boto.ec2.address.Address object 
          ref: http://boto.cloudhackers.com/en/latest/ref/ec2.html#module-boto.ec2.address
  '''
  if not awsconnector:
    logger.log('missing required awsconnector', logger.state.error)
    return False

  new_eip = None

  try:
    new_eip = awsconnector.allocate_address(domain=domain)
  except Exception as e:
    logger.log('Failed to allocate address: {0}'.format(e), logger.state.error)
    return None

  return new_eip


def get_aws_elasticips(awsconnector=None):
  '''
  This function gets the list of available Elastic Ips for a given aws region
  input: valid boto aws connector

  return: True|False , []
          list of all elastic ips for a given aws region
  '''
  if not awsconnector:
    logger.log('valid awsconnector required', logger.state.error)
 
  e_ips = awsconnector.get_all_addresses()

  ips = []
  eip = {}
  
  for a in e_ips:
    if a.domain.lower() == 'vpc':
      eip[a.public_ip] = a.allocation_id

  ips.append(eip)

  if ips:
    return True, ips

  return False, []


def create_aws_connector(aws_id=None, aws_key=None, region=None):
  '''
  creates an aws connector using boto library
  region - optional. aws region without AZ. Example us-east-1 
  aws_id - required. the aws id for the region/environment specified (got from pillar)
  aws_key - required. the aws key for the region/environment specified (got from pillar)
  '''
  if not aws_id or not aws_key:
    logger.log('valid aws ID and key are required', logger.state.error)

  if region:
    conn = ec2.connection.EC2Connection(aws_id, aws_key, region=ec2.get_region(region))
  else:
    conn = ec2.connection.EC2Connection(aws_id, aws_key)

  if conn:
    return conn

  logger.log('Failed to create boto aws connector.', logger.state.error)
  
  return None

def delete_rule_from_security_group(region=None, groupid=None, group=None, protocol=None, port=None, cidr=None, sourcegroup=None):
  '''
  group - str groupname that rule is being removed from
  groupid - str group id if not using groupname
  protocol - str protocol, aws supported
  port - str port, aws supported, single or range (min-max)
  cidr - str cidr: 0.0.0.0/0 etc...(don't use if passing in sourcegroup)

  results:
    True|False
  '''
  output = []

  if not group and not groupid:
    logger.log('missing either security groupid or groupname to remove rule from', logger.state.error)
    return False

  if not protocol or not port:
    logger.log('missing protocol or port parameters', logger.state.error)
    return False

  _source = None

  if not cidr and not sourcegroup:
    logger.log('either cidr or sourcegroup are required', logger.state.error)
    return False
  
  if cidr: 
    _source = '--cidr {0}'.format(cidr)
  if sourcegroup:
    _source = '--source-group {0}'.format(sourcegroup)

  if groupid: 
    _group = '--group-id {0}'.format(groupid)
  else:
    _group = '--group-name {0}'.format(group)

  try:
    cmd = 'aws ec2 revoke-security-group-ingress {0} --protocol {1} --port {2} --region {3} {4}'.format(_group, protocol, port, region, _source)
    
    logger.log('exec: {0}\n'.format(cmd))

    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('Failed to remove rule to security group {0}'.format(e), logger.state.error)

  output, errout = mycmd.communicate()

  try:
    ret = dict(ast.literal_eval(output.replace('\n','')))
  except Exception as e:
    logger.log('bad return from revoke-security-group-ingress: {0}'.format(e), logger.state.error)
    logger.log('assuming rule was not removed')
    return False

  if isinstance(ret, dict):
    if ret['return'] == 'false':
      logger.log('Failed to remove rule!', logger.state.error)
      return False
    else:
      logger.log('Rule successfully removed.')
      return True
  else:
    if 'true' in ret:
      return True
    else:
      return False

def add_rule_to_security_group(region=None, groupid=None, group=None, protocol=None, port=None, cidr=None, sourcegroup=None):
  '''
  group - str groupname
  groupid - str group id if not using groupname
  protocol - str protocol, aws supported
  port - str port, aws supported, single or range (min-max)
  cidr - str cidr: 0.0.0.0/0 etc...(don't use if passing in sourcegroup)
  sourcegroup - security group, valid aws group (don't use if passing cidr)

  results:
    True|False
  '''
  output = []

  if not group and not groupid:
    logger.log('missing either security groupid or groupname to add rule to', logger.state.error)
    return False

  if not protocol or not port:
    logger.log('missing protocol or port parameters', logger.state.error)
    return False

  _source = None

  if not cidr and not sourcegroup:
    logger.log('either cidr or sourcegroup are required', logger.state.error)
    return False
  
  if cidr: 
    _source = '--cidr {0}'.format(cidr)
  if sourcegroup:
    _source = '--source-group {0}'.format(sourcegroup)

  if groupid: 
    _group = '--group-id {0}'.format(groupid)
  else:
    _group = '--group-name {0}'.format(group)

  try:
    if protocol == 'all': #port ignored
      cmd = 'aws ec2 authorize-security-group-ingress {0} --protocol {1} --region {2} {3}'.format( \
              _group, protocol, region, _source)
    else:
      cmd = 'aws ec2 authorize-security-group-ingress {0} --protocol {1} --port {2} --region {3} {4}'.format( \
              _group, protocol, port, region, _source)
    logger.log(cmd)

    print '**** debug:\n', cmd

    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('Failed to add rule to security group {0}'.format(e), logger.state.error)
  output, errout = mycmd.communicate()

  if errout:
    logger.log(errout, logger.state.error)
    return False

  if output:
    logger.log(output)
    try:
      ret = dict(ast.literal_eval(output.replace('\n','')))
    except Exception as e:
      logger.log('Failed to set rule: {0}'.format(e))
      logger.log('rule may already exist')
      return False
    if isinstance(ret, dict):
      if ret['return'] == 'false':
        logger.log('Failed to add rule', logger.state.error)
        return False
      else:
        logger.log('Rule successfully added.')
        return True
    else:
      if 'true' in ret:
        return True
      else:
        return False

  return True


def get_security_groupid_with_filters(awsconnector=None, groupname=None, region=None):
  ''' 
  Inputs:
    awsconnector - valid connector - optional
    groupname - valid aws sec group - required
    region - valid aws region - required

  Return: None or groupid
  '''

  if not groupname or not region:
    logger.log('missing parameters. valid groupname and region must be specified', logger.state.error)
    return None

  if awsconnector:

    # NOTE: boto api call get_all_security_groups() allows for groupname filter. However, instead
    # of returning an empty list if the groupnames in the filter do not exist, it throws an exception
    # and dumps the stack. STUPID!!! 
    # So we have to call without filters and check for the group we are testing for 

    secgroups = awsconnector.get_all_security_groups()
    if secgroups:
      exists = False
      for sg in secgroups:
        if groupname == sg.name:
          exists = True

    if not exists:
      logger.log('specified security group {0} does not exist'.format(groupname), logger.state.error)
      return None

  output = []

  cmd = 'aws ec2 describe-security-groups --region {0} --filters Name=group-name,Values={1}'.format(region, groupname)
  print cmd

  if debug:
    logger.log('exec: {0}'.format(cmd))

  try:
    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('Failed to lookup security group: {0}'.format(e), logger.state.error)
    return None

  output, errout = mycmd.communicate()

  _group = output.strip()

  try:
    grp_dict = dict(json.loads(_group))
  except Exception as e:
    logger.log('Failed to convert sec group data to dict, might be empty json\n{0}\n'.format(e), logger.state.error)
    return None

  group_id = None
  for k, v in grp_dict.iteritems():
    for i in v:
      if 'GroupId' in i:
        group_id = i['GroupId']

  return group_id


def get_security_groupid(awsconnector=None, groupname=None, region=None):
  '''
  Inputs:
    awsconnector - valid connector - optional
    groupname - valid aws sec group - required
    region - valid aws region - required

  Return: None or groupid
  '''
  if not groupname or not region:
    logger.log('missing parameters. valid groupname and region must be specified', logger.state.error)
    return None

  if awsconnector:

    # NOTE: boto api call get_all_security_groups() allows for groupname filter. However, instead
    # of returning an empty list if the groupnames in the filter do not exist, it throws an exception
    # and dumps the stack. STUPID!!! 
    # So we have to call without filters and check for the group we are testing for 

    secgroups = awsconnector.get_all_security_groups()
    if secgroups:
      exists = False
      for sg in secgroups:
        if groupname == sg.name:
          exists = True

    if not exists:
      logger.log('specified security group {0} does not exist'.format(groupname), logger.state.warning)
      return None

  output = []

  cmd = 'aws ec2 describe-security-groups --group-name {0} --region {1}'.format(groupname, region)

  print cmd

  if debug:
    logger.log(cmd)

  try:
    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('Failed to lookup security group: {0}'.format(e), logger.state.error)
    return None

  output, errout = mycmd.communicate()
  _group = output.strip()

  try:
    grp_dict = dict(json.loads(_group))
  except Exception as e:
    logger.log('Failed to convert sec group data to dict, might be empty json\n{0}\n'.format(e), logger.state.warning)
    return None

  group_id = None
  for k, v in grp_dict.iteritems():
    for i in v:
      if 'GroupId' in i:
        group_id = i['GroupId']

  return group_id

def delete_security_group(awsconnector=None, groupname=None, region=None):
  '''
  delete aws security group
  conn - valid aws region boto connector (not used yet)
  groupname - security group name to delete
  region - aws region where the security group is
  
  return: True|False

  Note: when the user inputs a region that has different zone than the zone that the vm's were created,
        the security group will not be deleted because the awsconnector will not be allowed to remove the 
        network interfaces. These are zone specific. 
        The only time this might be an issue is if there are no vm's to terminate and the user runs
        destroyinstance() again to clean up residual elb's sec groups etc...
        in this case there is no was to verify the zone was correct because sec groups are not zone specific
        but the network interfaces are. We simply can only return false from here in that case.
  '''

  #TODO: change method to use optionally use AWS connector

  if not region or not groupname:
    logger.log('region and groupname are required', logger.state.error)
    return False

  groupid = get_security_groupid_with_filters(awsconnector=awsconnector, groupname=groupname, region=region)

  if not groupid:
    logger.log('requested security group does not exist: {0}'.format(groupname))
    print 'requested security group does not exist: {0}'.format(groupname)
    return True

  output = []

  results, removed = remove_network_interfaces_from_security_group(awsconnector=awsconnector, secgroup=groupname, retry=40, wait=3)
  if not results:
    logger.log('Failed to remove one or more network interface dependency objects', logger.state.error)

  try:
    cmd = 'aws ec2 delete-security-group --group-id {0} --region {1}'.format(groupid, region)
    if debug:
      logger.log(cmd)

    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('Failed to delete security group: {0}'.format(e), logger.state.error)
    return False

  output, errout = mycmd.communicate()
  # output is str

  try:
    ret = dict(ast.literal_eval(output.replace('\n','')))
  
    if isinstance(ret, dict):
      if ret['return'] == 'false':
        logger.log('Failed to delete security group {0}'.format(groupname), logger.state.error)
        return False
      else:
        logger.log('Removed security group {0}'.format(groupname))
        return True
    else:
      if 'true' in ret:
        return True
      else:
        return False
  except:
    logger.log('cannot determine status of security group delete. You may want to check yourself', logger.state.warning)
    logger.log('output from aws: {0}'.format(output))
    logger.log('result code: {0}'.format(errout))
    return True 


def create_security_group(awsconnector=None, data={}):
  '''
  create new security group
  conn - valid connector to aws region
  data - dict of vpc_id, region, env, groupdetails dict

  return:
  str groupname, dict groupid
  or
  None, {}
  '''

  newgroup = None

  if not data:
    logger.log('valid data dict is required', logger.state.error)
    return None, {}

  if not 'env' in data or \
     not 'vpc_id' in data or \
     not 'region' in data or \
     not 'new-group' in data:
    return None, {}

  output = []
  groupname = data['new-group']['name']

  # FIRST CHECK TO SEE IF THE GROUP ALREADY EXISTS, IF SO REMOVE IT
  # TODO: add check if any instances are using it

  grpid = get_security_groupid(awsconnector=awsconnector, groupname=groupname, region=data['region'])

  if grpid:
    ret = False
    if awsconnector:
      results, removed = remove_network_interfaces_from_security_group(awsconnector=awsconnector, secgroup=groupname, retry=40, wait=3)
      if not results:
        logger.log('Failed to remove one or more network interface dependency objects.', logger.state.error)

    ret = delete_security_group(awsconnector=awsconnector, groupname=groupname, region=data['region'])

    if not ret:
      logger.log('Failed to delete security group {0} {1}\n{2}\n'.format(groupname, grpid, errout), logger.state.error)
      return None, {}


  #TODO: update to use connector input
  try:
    cmd = 'aws ec2 create-security-group --group-name {0} --description \'vmi cloud ops security group\' ' \
          '--region {1} --vpc-id {2}'.format(groupname, data['region'], data['vpc_id'])

    print cmd

    logger.log('creating security group {0}'.format(groupname))

    if debug:
      logger.log(cmd)

    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    print 'Failed attempt to create security group:\n{0}'.format(e)
    logger.log('Failed attempt to create security group:\n{0}'.format(e), logger.state.error)

  output, errout = mycmd.communicate()
  newgroup = output.strip()

  if errout:
    logger.log('Failed to create security group: {0}'.format(errout))
    return None, {}

  try:
    grp_dict = dict(json.loads(newgroup))
  except Exception as e:
    logger.log('Failed to convert sec group data to dict, might be empty json\n{0}\n'.format(e), logger.state.warning)
    return None, {}

  group_id = None
  if isinstance(grp_dict, dict):
    if 'GroupId' in grp_dict:
      group_id = grp_dict['GroupId']
  if not group_id:
    logger.log('Failed to determine GroupId for new sec group {0}, abort'.format(newgroup), logger.state.error)
    return None, {}


  '''
  # add rules to security group
  # TODO:// maybe make these rules a structure in pillar and pull from there??
  if not add_rule_to_security_group(groupid=group_id, protocol="tcp", port="22", cidr="0.0.0.0/0", region=data['region']):
    logger.log('failed to set rule on security group', logger.state.error)
  if not add_rule_to_security_group(groupid=group_id, protocol="tcp", port="80", cidr="0.0.0.0/0", region=data['region']):
    logger.log('failed to set rule on security group', logger.state.error)
  if not add_rule_to_security_group(groupid=group_id, protocol="icmp", port="all", cidr="0.0.0.0/0", region=data['region']):
    logger.log('failed to set rule on security group', logger.state.error)
  if not add_rule_to_security_group(groupid=group_id, protocol="tcp", port="0-65535", sourcegroup=group_id, region=data['region']):
    logger.log('failed to set rule on security group', logger.state.error)
  if 'master_secgrp' in data:
    if not add_rule_to_security_group(groupid=group_id, protocol="tcp", port="0-65535", sourcegroup=data['master_secgrp'], region=data['region']):
      logger.log('failed to set rule on security group', logger.state.error)
    # WE NEED TO ADD A RULE ON THE MASTER GROUP TO GIVE THE NEW NE GROUP ACCESS BACK TO SALT MASTER
    if not add_rule_to_security_group(groupid=data['master_secgrp'], protocol="tcp", port="0-65535", sourcegroup=group_id, region=data['region']):
      logger.log('Failed to set rule on Master security group'.format(data['master_secgrp']), logger.state.error)

  # FOR ACCESS FROM DISPATCHER ELB TO NE NODES
  if 'public_secgrp' in data:
    if not add_rule_to_security_group(groupid=group_id, protocol="tcp", port="0-65535", sourcegroup=data['public_secgrp'], region=data['region']):
      logger.log('Failed to set public group rule on security group', logger.state.error)
  '''

  if 'rules' in data['new-group'] and isinstance(data['new-group']['rules'], dict):
    #print '*** debug group has rules....'
    for rule, value in data['new-group']['rules'].iteritems():
      #print '*** debug the rule:', rule, value
      _cidr = rule #rule in pillar is the source
      _port = None
      _protocol = None
      if isinstance(value, dict):
        if 'port' in value:
          _port = value['port']
        if 'protocol' in value:
          _protocol = value['protocol']
  
      if _port and _protocol:
        if not add_rule_to_security_group(groupid=group_id, protocol=_protocol, port=_port, cidr=_cidr, region=data['region']):
          logger.log('Failed to set rule {0} {1} on security group {2}'.format(_port, _protocol, group_id), logger.state.error)

  return groupname, newgroup


def call_saltcloud(mapfile=None, debug=False):
  '''
  invoke salt-cloud engine with mapfile
  mapfile - valid salt cloud map file
  returns:
    True|False, None
 
  ref: https://github.com/saltstack/salt/blob/develop/salt/modules/cloud.py
       for api access to salt cloud functions directly. such as destroy etc.... 
  second return object will be None on failure, contains salt-cloud output in json on success
  '''
  if not mapfile:
    logger.log('mapfile is required', logger.state.error)
    return False, None
  else:
    logger.log('Processing cloud map')

    if debug:
      logger.log('running salt-cloud in debug')
      exec_cmd = 'salt-cloud -m {0} -y -P --out=json -l debug'.format(mapfile)
    else:
      exec_cmd = 'salt-cloud -m {0} -y -P --out=json'.format(mapfile)
   
    print 'SALT-CLOUD\n', exec_cmd
 
    output = []
 
    try:
      mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )

    except Exception as e:
      logger.log('Failed to run salt-cloud: {0}'.format(e))
      return False, None

    logger.log('waiting on salt-cloud.........')

    output, errout = mycmd.communicate()
    if errout:
      logger.log('salt-cloud failed: {0}'.format(errout))
      logger.log(exec_cmd)

  logger.log('returning with salt-cloud data')

  return True, output

   
def create_new_cloud_meta(node, data):
  '''
  create metadata structure of specific items in saltcloud return
  input:
  node - fqdn host name
  data - saltcloud return json data
  '''
 
  try: 

    node_data = {}  
    meta = {}  

    for k,v in data.items():
      if k == 'instanceId':
        meta['instance_id'] = v 

      if k == 'subnetId':
        meta['subnet'] = v 

      if k == 'privateIpAddress':
        meta['private_ip'] = v 
        meta['internal_host'] = 'ip-{0}'.format(v)

      if k == 'privateDnsName':
        meta['private_dns'] = v 

      if k == 'ipAddress':
        meta['public_ip'] = v 

      if k == 'dnsName':
        meta['public_dns'] = v 

    node_data[node] = meta 

  except:
    logger.log('Failed to create node metadata', logger.state.error)
    return False, node_data

  return True, node_data

def get_aws_instance_map(awsconnector=None):
  '''  
  Inputs:
    awsconnector - valid boto aws region connector

  Return: list of all aws instances in given region
          List members are Dict {ID: Name}
          empty list on fail
  '''
  if not awsconnector:
    logger.log('Valid aws boto connector must be specified in awsconnector param', logger.state.error)
    return []

  results, instances = get_aws_instances(awsconnector=awsconnector)

  allinstances = [] 

  if results and isinstance(instances, list):
    for i in instances:
      node_id_map = {} 
      if 'id' in i.__dict__ and 'tags' in i.__dict__:
        if 'Name' in i.__dict__['tags']:
          node_id_map[i.__dict__['id']] = i.__dict__['tags']['Name']

      allinstances.append(node_id_map)

  return allinstances

def _destroy_aws_nodes(region=None, mapdir=None, match=None):
  '''  
  remove all nodes from aws of a specific filter
  input:
  region = valid aws region 
  mapdir - path to cloud map
  match - valid minion filter
  return output [], region STRING
  '''
  if not mapdir or not match or not region:
    logger.log('region, mapdir and match are required parameters', logger.state.error)
    return [], region

  mapfile = None 
  for filename in os.listdir(mapdir):
    if filename.endswith(".map"):
        if match in filename:
          mapfile = '{0}/{1}'.format(mapdir, filename)
          logger.log('destroying with using mapfile {0}'.format(mapfile))

  if not mapfile:
    logger.log('cannot determine map file to use.', logger.state.error)
    return [], region

  output = [] 

  try: 
    cmd = 'salt-cloud -m {0} -d -y --out json'.format(mapfile)
    mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('Failed to remove nodes using salt-cloud: {0}'.format(e), logger.state.error)
    return [], region

  output, errout = mycmd.communicate()
  if errout:
    logger.log('salt-cloud run may not have completed successful: {0}'.format(errout), logger.state.warning)

  return output, region

def terminate_instances_wait(region=None, ids=[]):
  '''  
  input:
  region = valid aws region 
  ids - list of instance ids
  return True|False
  '''

  if not ids or not region:
    logger.log('region and ids[] are required parameters', logger.state.error)

  ec2_conn = ec2.connect_to_region(region)

  completed = False

  # LOOP EACH NODE AND CHECK CURRENT STATUS. IF ANY ARE NOT terminated, MAKE CALL AGAIN
  logger.log('waiting on aws destroy terminated status')

  # JUST EXECUTE TERMINATE, AND DON'T USE THE RETURN OBJECT
  # ITERATE THE PASSED IN IDS LIST FOR STATUS

  result = ec2_conn.terminate_instances(instance_ids=ids)

  sys.stdout.flush()
  while not completed:
    sys.stdout.write('. ')
    sys.stdout.flush()

    completed = True 

    if ids:
      for i in ids:
        details = ec2_conn.get_all_instances(instance_ids=''.join(i))
        for x in details:
          print i, x.instances[0].state
          if not x.instances[0].state == 'terminated':
            completed = False
    time.sleep(3)
 
  print '\ndone terminating instances'

  return True


def terminate_instances(region=None, mapdir=None, match=None):
  '''  
  wrap and evalute results of calls to aws destroy
  input:
  region = valid aws region 
  mapdir - path to cloud map
  match - valid minion filter
  return True|False
  '''

  if not mapdir or not match or not region:
    logger.log('region, mapdir and match are required parameters', logger.state.error)
 
  completed = False
  region_of_instance = None 
  # LOOP EACH NODE AND CHECK CURRENT STATUS. IF ANY ARE NOT terminated, MAKE CALL AGAIN
  logger.log('waiting on aws destroy terminated status')

  sys.stdout.flush()
  while not completed:
    sys.stdout.write('. ')
    sys.stdout.flush()
    completed = True 

    aws_ret, region_of_instance = _destroy_aws_nodes(region=region, mapdir=mapdir, match=match)

    if aws_ret: 
      # PUT IN THIS IF BECAUSE AFTER UPGRADE TO 2015.8.5, SUBSEQUENT CALLS TO SALT-CLOUD -d RETURN EMPTY. 
      # NEED ANOTHER WAY TO WAIT FOR 'terminated' AWS INSTANCE STATE 
      ret = None 
      try: 
        ret = json.loads(aws_ret)
      except:
        logger.log('aws return uncertain: {0}'.format(aws_ret), logger.state.warning)

      if ret and isinstance(ret, dict):
        for region, conf in ret.items():
          for provider, nodes in conf.items():
            for node, nodecfg in nodes.items():

              if nodecfg['currentState']['name'].lower() != 'terminated':
                completed = False
      else:
        logger.log('Cannot wait on aws detroy node status anymore, continue', logger.state.warning)

  print '\n'

  return True

def get_subnet_id(subnet=None):
  '''
  inputs: 
    subnet - string name of subnet to retreive
  return:
    aws subnetID
  '''

def create_subnet(region=None, data={}):
  '''
  Create Single subnet in AWS

  inputs:
    region - valid aws region such as us-east-1
    data - nested dict of details to provide {vpc_id, new-subnet{}}
  return:
    True|False, aws subnetID|None
  '''

  import boto.vpc

  conn = boto.vpc.connect_to_region(region)

  if not data:
    logger.log('Valid data= dict must be specified', logger.state.error)
    return False, None

  _vpcid = None
  _cidr = None
  _zone = None
  _name = "no name"

  if isinstance(data, dict):
    for k,v in data.iteritems():
      if k == 'vpc_id':
        _vpcid = v

      if k == 'new-subnet':
        if isinstance(v, dict):
          if 'name' in v:
            _name = v['name']
          if 'cidr' in v:
            _cidr = v['cidr']  
          if 'zone' in v:
            _zone = v['zone']

    if not _vpcid or not _cidr:
      return False, None

    try:
      # have to specify the vpc even though we are connected to one
      if _zone:
        subnet = conn.create_subnet(_vpcid, _cidr, '{0}{1}'.format(region,_zone))
      else:
        subnet = conn.create_subnet(_vpcid, _cidr)
    except Exception as e:
      logger.log('Failed to create subnet {0}: {1}'.format(_name, str(e.message)), logger.state.error)

      print 'Failed to create subnet {0}: {1}'.format(_name, str(e.message))

      return False, None

  return True, subnet

def delete_route_table(region=None, tableid=None):
  '''
  inputs:
    region - aws region
    tableid - table id
  return:
    True|False
  '''

  import boto.vpc

  if not region:
    logger.log('Valid region, example us-east-1, must be specified', logger.state.error)
    return False 

  conn = boto.vpc.connect_to_region(region)

  result = conn.delete_route_table(tableid)

  print result

  return True


def delete_internet_gateway(region=None, gatewayid=None):
  '''
  inputs:
    region - aws region
    gatewayid - gateway id
  return:
    True|False
  '''

  import boto.vpc

  if not region:
    logger.log('Valid region, example us-east-1, must be specified', logger.state.error)
    return False 

  conn = boto.vpc.connect_to_region(region)

  result = conn.delete_internet_gateway(gatewayid)

  print result

  return True


def delete_subnet(region=None, subnetid=None):
  '''
  inputs:
    region - aws region
    subnet - subnet id
  return:
    True|False
  '''

  import boto.vpc

  if not region:
    logger.log('Valid region, example us-east-1, must be specified', logger.state.error)
    return False 

  conn = boto.vpc.connect_to_region(region)

  result = conn.delete_subnet(subnetid)

  print result

  return True


def create_vpc(ec2conn=None, region=None, data={}):
  '''
  Function create new AWS vpc for specified region.
  Add modifiers, create gateway and route table and attches to vpc
  
  inputs:
    ec2conn - established ec2 connected region connector, this is only used to call create_tag
    region - valid aws region such as us-east-1
    data - dict of details to provide {cidr, enabledns, enablehostnames, management-vpc} 
  return:
    aws True|False, vpcID|None
  '''

  import boto.vpc

  if not region:
    logger.log('Valid region, example us-east-1, must be specified', logger.state.error)
    return False, None

  conn = boto.vpc.connect_to_region(region)


  if not data:
    logger.log('Valid data= dict must be specified', logger.state.error)
    return False, None

  if not 'cidr' in data:
    logger.log('new vpc details are missing cidr block', logger.state.error)
    return False, None

  if not 'management-vpc' in data:
    logger.log('new vpc requires peering to management-vpc which is missing', logger.state.error)
    return False, None

  vpc = conn.create_vpc(data['cidr'])

  if not vpc.id:
    logger.log('failed to create vpc, no id', logger.state.error)
    return False, None
  logger.log('created new vpc {0}'.format(vpc.id))

  # tag vpc
  ids = str(vpc.id).split()
  tags = {'Name': '{0}'.format(data['name'])}
  if not create_tag(awsconnector=ec2conn, ids=ids, tags=tags):
    logger.log('failed to tag new vpc {0}'.format(vpc.id), logger.state.warning)

  try:
    conn.modify_vpc_attribute(vpc.id, enable_dns_support=data['enable-dns'])
  except:
    logger.log('failed to set vpc modifer enable dns', logger.state.warning)
  logger.log('modified attribute on new vpc {0}'.format(vpc.id))

  try:
    conn.modify_vpc_attribute(vpc.id, enable_dns_hostnames=data['enable-hostnames'])
  except:
    logger.log('failed to set vpc modifer enable hostnames', logger.state.warning)
  logger.log('modified attribute on new  vpc {0}'.format(vpc.id))

  try:
    gateway = conn.create_internet_gateway()
  except:
    logger.log('failed to create internet gateway', logger.state.error)
    return False, vpc.id
  logger.log('created new gateway {0} for vpc {1}'.format(gateway.id, vpc.id))

  if ec2conn:
    ids = str(gateway.id).split()
    tags = {'Name': 'IG-{0}'.format(data['name'])}
    if not create_tag(awsconnector=ec2conn, ids=ids, tags=tags):
      logger.log('failed to tag new gateway {0}'.format(gateway.id), logger.state.warning)
 
  try:
    conn.attach_internet_gateway(gateway.id, vpc.id)
  except:
    logger.log('failed to attach gateway {0} to vpc {1}'.format(gateway.id, vpc.id), logger.state.error)
    return False, vpc.id
  logger.log('attached gateway to new vpc {0}'.format(vpc.id))

  try:
    route_table = conn.create_route_table(vpc.id)
  except:
    logger.log('failed to create route table for vpc {0}'.format(vpc.id), logger.state.error)
    return False, vpc.id
  logger.log('created new route table {0} for vpc {1}'.format(route_table.id, vpc.id))

  if ec2conn:
    ids = str(route_table.id).split()
    tags = {'Name': 'ROUTE-{0}'.format(data['name'])}
    if not create_tag(awsconnector=ec2conn, ids=ids, tags=tags):
      logger.log('failed to tag new route_table {0}'.format(route_table.id), logger.state.warning)

  tables = conn.get_all_route_tables()
  for t in tables:
    if t.vpc_id == vpc.id:
      print 'matched', t.id, t.vpc_id, '\n'

      # ADD INTERNET ACCESS TO ROUTE TABLE. VERY IMMPORTANT! WITHOUT THIS, SALT MASTER CANNOT BOOTSTRAP NEW VM
      try:
        inet_route = conn.create_route(t.id, '0.0.0.0/0', gateway.id)
        logger.log('create_route returned: {0}'.format(inet_route))
      except:
        logger.log('failed to add inet route to {0} for vpc {1}'.format(t.id, vpc.id), logger.state.error)
        return False, vpc.id


  # CREATE PEERING CONNECTION WITH MANAGEMENT VPC IMPORTANT, SALT CANNOT BOOTSTRAP MINION OTERWISE
  try:
    pc = conn.create_vpc_peering_connection(vpc.id, data['management-vpc'])
    print 'peeering connection:', pc
    print dir(pc)

    if ec2conn:
      ids = str(pc.id).split()
      tags = {'Name': 'PEER-{0}'.format(data['name'])}
      if not create_tag(awsconnector=ec2conn, ids=ids, tags=tags):
        logger.log('failed to tag new peering {0}'.format(pc.id), logger.state.warning)
 
    pc_all = conn.get_all_vpc_peering_connections()
    for p in pc_all:
      print p.id, p.status_code, str(p.status_code)      
      if 'pending-acceptance' in str(p.status_code):
        print 'accepting peering connection'
        p = conn.accept_vpc_peering_connection(p.id)
        p.update()

    time.sleep(2)
    print 'check tables again....'
    pc_all = conn.get_all_vpc_peering_connections()
    for p in pc_all:
      print p.id, p.status_code, str(p.status_code)      


  except:
    logger.log('failed to peer with vpc {0}'.format(data['management-vpc']), logger.state.error)
    return False, vpc.id

  logger.log('returning success with new vpc {0}'.format(vpc.id))

  return True, vpc.id

def delete_vpc(region=None, vpcid=None):
  '''  
  inputs:
    region - valid aws region such as us-east-1
  return:
    True|False
  '''

  if not vpcid:
    logger.log('vpcid must be specified.')
    return False
 
  import boto.vpc

  if not region:
    logger.log('Valid region, example us-east-1, must be specified', logger.state.error)
    return False 

  conn = boto.vpc.connect_to_region(region)

  result = conn.delete_vpc(vpcid)

  print result

  return True

def vpc_exists(region=None, vpcname=None):
  '''
   inputs:
    region - valid aws region such as us-east-1
    vpcname - the Name tag of the vpc 
  return:
    True - exists
    False - not exists
  '''
  if not vpcname:
    raise ValueError('vpcname must be specified.')
 
  import boto.vpc

  if not region:
    raise ValueError('Valid region, example us-east-1, must be specified')

  conn = boto.vpc.connect_to_region(region)
  
  tags = conn.get_all_tags()

  for t in tags:
    if t.value.upper() ==  vpcname and t.res_type == 'vpc':
      logger.log('VPC already exists!')
      return True

  return False

def vpcid_exists(region=None, vpcid=None):
  '''
   inputs:
    region - valid aws region such as us-east-1
    vpcname - valid aws vpcId
  return:
    True - exists
    False - not exists
  '''
  if not vpcid:
    raise ValueError('vpcid must be specified.')
 
  import boto.vpc

  if not region:
    raise ValueError('Valid region, example us-east-1, must be specified')

  conn = boto.vpc.connect_to_region(region)
  
  tags = conn.get_all_tags()

  for t in tags:
    if t.res_id ==  vpcid and t.res_type == 'vpc':
      logger.log('VPC exists!')
      return True

  return False

