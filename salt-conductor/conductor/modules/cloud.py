'''
cloud.py 
Conductor salt runner submodule
Purpose:
Salt runner interface for AWS cloud infrastructure object provisioning
such as environment vpc's, DTE's, sandbox's
'''

from __future__ import absolute_import
import os, sys 

from conductor import Conductor
from modules import conductor_common as cc
from modules import load_product as lp
from common import aws as awsc
from common.utility import Logger
from common import utility as util

import simplejson as json 
import yaml 
import random
import inspect
import time 
from datetime import datetime, timedelta
import ast 
# Import salt libs
import salt.pillar
import salt.utils.minions
import salt.client
import subprocess
import boto.ec2
import re

logger = Logger(shell=True)

# create instance of Conductor()
conductor = lp.load('CLOUD')
conductor.productconf = conductor.PGROUP.Conf()

# set aws module logger shell to true. we init this as false in common.aws
awsc.logger.shell = True

this_module = __name__.split('.')[1]


def _create_security_groups(vpc=None, vpcid=None, vpcname=None):
  '''
  vpc - should be in the form vpc.XXX where XXX is the type of vpc in pillar
  vpcid - valid aws vpcID
  '''
  if not vpc or not vpcid:
    logger.log('vpc type and vpcID required', logger.state.error)
    return False

   # this is used only to visual show the vpc that subnet is on 
  if not vpcname:
    vpcname = 'name'

  def _fill_secgrp(value):
    '''
    returns list of dict of groups details
    '''
    groups = []
    data = {}
    obj = conductor.pillar_tree[vpc]['security-groups']
    try:
      if value in obj:
        if isinstance(obj[value], dict):
          for k,v in obj[value].iteritems():
            data = {}
            data['name'] = '{0}-{1}'.format(vpcname, k)
            data['tagname'] = '{0}-{1}'.format(vpcname, k)
            if isinstance(v, dict):
              if 'rules' in v and isinstance(v['rules'], dict):
                data['rules'] = v['rules']
            groups.append(data)

    except:
      logger.log('Failed to find {0} in security-groups pillar'.format(value), logger.state.warning)

    return groups

  private_secgroup = _fill_secgrp('private')
  public_secgroup = _fill_secgrp('public')
  mgmt_secgroup = _fill_secgrp('management')

  _group_data = {}
  _group_data['region'] = conductor.region[:-1]
  _group_data['vpc_id'] = vpcid
  _group_data['env'] = conductor.pillarenv


  def tag_resource(data):
    '''
    data - aws security group resource json block
    '''
    try: 
      _dict = dict(json.loads(data))
    except Exception as e:
      logger.log('Failed to convert security group data to dict, might be invalid json\n{0}\n'.format(e), logger.state.error)
      pass
    # EXTRACT SECURITY GROUP ID VAR, TAG IF FOUND 
    group_id = None 
    if isinstance(_dict, dict):
      if 'GroupId' in _dict:
        group_id = _dict['GroupId']
    if group_id:
      ids = str(group_id).split()
      tags = {'Name': '{0}'.format(g['tagname'])}
      tag_resource = awsc.create_tag(awsconnector=conductor.AWS_CONNECT, ids=ids, tags=tags)
      if not tag_resource:
        logger.log('failed to name security group {0}'.format(group_id))
    return 

  if mgmt_secgroup:
    for g in mgmt_secgroup:
      _group_data['new-group'] = g
      security_group, security_grp_json = awsc.create_security_group(awsconnector=conductor.AWS_CONNECT, \
                                                                     data=_group_data)
      tag_resource(security_grp_json)

  if public_secgroup:
    for g in public_secgroup:
      _group_data['new-group'] = g
      security_group, security_grp_json = awsc.create_security_group(awsconnector=conductor.AWS_CONNECT, \
                                                                     data=_group_data)
      tag_resource(security_grp_json)

  if private_secgroup:
    for g in private_secgroup:
      _group_data['new-group'] = g
      security_group, security_grp_json = awsc.create_security_group(awsconnector=conductor.AWS_CONNECT, \
                                                                     data=_group_data)
      tag_resource(security_grp_json)

  if not security_group:
    logger.log('Failed to create new security groups')
    return {}
  else:
    logger.log('Created new security groups:\n{0}'.format(security_grp_json))

  return True


def _create_subnets(vpc=None, vpcid=None, vpcname=None):
  '''
  vpc - should be in the form vpc.XXX where XXX is the type of vpc in pillar
  vpcid - valid aws vpcID
  '''
  if not vpc or not vpcid:
    logger.log('vpc (type) and vpcid (ID) required', logger.state.error)
    return False
   
  # this is used only to visual show the vpc that subnet is on 
  if not vpcname:
    vpcname = 'name'

  def _fill_subnet(value):
    subnets = []
    data = {}
    obj = conductor.pillar_tree[vpc]['subnets']
    try:
      if value in obj:
        if isinstance(obj[value], dict):
          for k,v in obj[value].iteritems():
            data = {}
            data['name'] = '{0}-{1}'.format(vpcname, k) 
            if isinstance(v, dict):
              # NEED THE NEXTID THAT WAS USED TO CREATE THE VPC IF DTE
              if 'cidr' in v:
                data['cidr'] = v['cidr']
              if 'zone' in v:
                data['zone'] = v['zone']

            subnets.append(data)

    except:
      logger.log('Failed to find {0} in subnets pillar'.format(value), logger.state.warning)

    return subnets

  private_subnet = _fill_subnet('private')
  public_subnet = _fill_subnet('public')
  subnets = {}
  subnets['vpc_id'] = vpcid
  if private_subnet:
    for s in private_subnet:
      subnets['new-subnet'] = s

      # NEEDED BECAUSE DTE CIDR MASK IS DYNAMIC
      if vpcname.startswith('DTE-'):  
        subnets['new-subnet']['cidr'] = str(s['cidr']).replace('XX', str(vpcname.split('-')[2]))


      result, subnet = awsc.create_subnet(region=conductor.region[:-1], \
                                     data=subnets)

      if result:
        logger.log('created new subnet {0} {1}'.format(subnet.id, s['name']))
        ids = str(subnet.id).split()
        tags = {'Name': '{0}'.format(s['name'])}
        tag_resource = awsc.create_tag(awsconnector=conductor.AWS_CONNECT, ids=ids, tags=tags)
        if not tag_resource:
          logger.log('failed to name subnet {0}'.format(subnet.id))
      else:
        logger.log('failed to create subnet {0}'.format(s['name']))

  if public_subnet:
    for s in public_subnet:
      subnets['new-subnet'] = s

      # NEEDED BECAUSE DTE CIDR MASK IS DYNAMIC 
      if vpcname.startswith('DTE-'):  
        subnets['new-subnet']['cidr'] = str(s['cidr']).replace('XX', str(vpcname.split('-')[2]))

      result, subnet = awsc.create_subnet(region=conductor.region[:-1], \
                                     data=subnets)

      if result:
        logger.log('created new subnet {0} {1}'.format(subnet.id, s['name']))
        ids = str(subnet.id).split()
        tags = {'Name': '{0}'.format(s['name'])}
        test = awsc.create_tag(awsconnector=conductor.AWS_CONNECT, ids=ids, tags=tags)
        if not test:
          logger.log('failed to name subnet {0}'.format(subnet.id))
      else:
        logger.log('failed to create subnet {0}'.format(s['name']))

  return True

def _build_cloud(vpc=None, vpcid=None):
  ''' 
  vpc - valid pillar vpc template (dte, dev, qa, etc...)
  '''
  if not vpc:
    logger.log('vpc (type, dte, dev, qa etc...) must be specified', logger.state.error)
    return False

  the_vpc = 'vpc.dte' #default

  if 'dte' == vpc:
    the_vpc = 'vpc.dte'
  else:
    the_vpc = 'vpc.{0}'.format(conductor.pillarenv)

  if vpcid:
    vpc_id = vpcid
    vpc_name = ''
  else:

    result, vpc_id, vpc_name = _create_vpc(vpc=the_vpc)

    if not result:
      logger.log('failed to create vpc {0}'.format(the_vpc), logger.state.error)
      return False, None


  # subnets
  if _create_subnets(vpc=the_vpc, vpcid=vpc_id, vpcname=vpc_name):
    logger.log('created subnets for {0} {1}'.format(the_vpc, vpc_id))
  else:
    logger.log('failed to create subnets for {0} {1}'.format(the_vpc, vpc_id), logger.state.error)

  # security groups
  if _create_security_groups(vpc=the_vpc, vpcid=vpc_id, vpcname=vpc_name):
    logger.log('created security groups for {0} {1}'.format(the_vpc, vpc_id))
  else:
    logger.log('failed to create security groups for {0} {1}'.format(the_vpc, vpc_id), logger.state.error)

  return True, vpc_id


def _create_vpc(vpc=None):
  '''
  This function gathers pillar data required to create a region/zone new vpc,
  then creates subnets and sec groups or whatever specified in pillar
  Returns:
    True|False, vpcid|None, vpcName|None
  '''

  if not vpc:
    logger.log('vpc.TYPE (type: dte, dev, qa etc...) must be specified', logger.state.error)
    return False, None, None

  vpcs = []
  data = {}

  the_vpc = vpc


  if not the_vpc in conductor.pillar_tree:
    logger.log('{0} config not found in pillar'.format(the_vpc), logger.state.error)
    return False, None, None

  cfg = conductor.pillar_tree[the_vpc]

  if not isinstance(cfg, dict) or not 'cidr' in cfg:
    logger.log('missing required cidr config pillar for {0}'.format(the_vpc), logger.state.error)
    return False, None, None
 

  def _verify_next(tags, suggest):
    for t in tags:
      if suggest == t.value:
        return True
    return False


  # look up all vpc tags for re-existing vpc to get the index of a new one
  import boto.vpc
  conn = boto.vpc.connect_to_region(conductor.region[:-1])
  tags = conn.get_all_tags()

  try:
    data = {}
    if the_vpc == 'vpc.dte':
      suggest = None
      nextid = 0
      taken = True
      while taken:
        nextid+=1
        suggest = 'DTE-{0}-{1}'.format(conductor.pillarenv.upper(), nextid)
        taken = _verify_next(tags, suggest)

      print 'setting new vpc name to', suggest
      
      data['name'] = suggest
      data['cidr'] = str(cfg['cidr']).replace('XX', str(nextid))
     
    else:

      # VERIFY THE VPC DOES NOT EXIST
      for t in tags:
        if t.value.upper() ==  vpc.split('.')[1].upper() and t.res_type == 'vpc':
          logger.log('ERROR. Cannot create VPC that already exists!', logger.state.error)
          return False, None, None

      data['name'] = '{0}'.format(vpc.split('.')[1].upper())
      data['cidr'] = cfg['cidr']


    data['enable-dns'] = False #default
    data['enable-hostnames'] = False #default
    data['management-vpc'] = conductor.management_vpc

    if 'enable-dns' in cfg:
      data['enable-dns'] = cfg['enable-dns']
    if 'enable-hostnames' in cfg:
      data['enable-hostnames'] = cfg['enable-hostnames']

    vpcs.append(data)

  except:
    pass

  if vpcs:
    for v in vpcs:
      result, vpc_id = awsc.create_vpc(ec2conn=conductor.AWS_CONNECT, region=conductor.region[:-1], \
                                       data=v)

      if not result:
        logger.log('failed to create vpc {0} or a dependency object, view /logs/conductor/aws.log for details'.format(v['name'], logger.state.error))
        return False, None, None

      return True, vpc_id, data['name']
 

def create(**kwargs):
  '''
  required input:
    pillarenv=xxx
    region=xxx
  
  other valid inputs:
    vpc=environment|dte [environment tells conductor to use pillarenv=xxx]
    shell= True|False
 
  command line examples:
  salt-run conduct.cloud create vpc=enviroment pillarenv=dev region=us-east-1b [builds DEV infrastructure]
  salt-run conduct.cloud create vpc=enviroment pillarenv=qa region=us-east-1b [builds QA infrastructure]
  salt-run conduct.cloud create vpc=dte pillarenv=dev region=us-east-1b [builds DEV-DTE-X infrastructure]

  example would create whatever aws object needed for a new zone. I.E. public subnet, private subnet etc...
  '''

  if not cc.initialize(conductor):
    return {}

  if not conductor.initialize(kwargs):
    print 'Conductor.initialize() failed. aws connector or pillar tree loading failed.'
    return {}

  if conductor.debug:
    print conductor.pillarenv
    print conductor.opts
    print conductor.region
    print conductor.debug

  if not util.verify_caller(this_module):
    logger.log('Cannot call submodules directly', logger.state.error)
    return{}

  if not cc.verify_pillar_requirements(conductor):
    return {}

  conductor.management_vpc = conductor.pillar_tree[conductor.region[:-1]]['management-vpc']


  # NEED THIS TO AVOID REBUILDING THE VPC MAYBE
  vpcid_arg = False
  if 'vpcid' in kwargs:
    vpcid_arg = kwargs['vpcid']

  if 'vpc' in kwargs:
    if vpcid_arg:
      result = _build_cloud(vpc=kwargs['vpc'], vpcid=vpcid_arg)
    else:
      result = _build_cloud(vpc=kwargs['vpc'])

    return {}

  return True


def destroy(**kwargs):
  '''
  use case for when we need to destroy an instance for the product group

  required input:
    pillarenv=xxx
    region=xxx
     
  other valid inputs:
    vpc=dte|environment [enviroment use pillarenv=xxx]
      dte=x [if vpc=dte]
    shell=True|False
 
  command line examples:
  salt-run conduct.cloud destroy vpc=dev pillarenv=dev region=us-east-1b [destroys DEV infrastructure]
  salt-run conduct.cloud destroy vpc=qa pillarenv=qa region=us-east-1b [destroys QA infrastructure]
  salt-run conduct.cloud destroy vpc=dte dte=1 pillarenv=dev region=us-east-1b [destroys DEV-DTE-1 infrastructure]
  '''

  if not cc.initialize(conductor):
    return {}

  if not conductor.initialize(kwargs):
    print 'initialize() failed. aws connector or pillar tree loading failed.'
    return {}

  if conductor.debug:
    print conductor.pillarenv
    print conductor.opts
    print conductor.region
    print conductor.debug

  if not util.verify_caller(this_module):
    logger.log('Cannot call submodules directly', logger.state.error)
    return{}

  if not cc.verify_pillar_requirements(conductor):
    return {}

  conductor.management_vpc = conductor.pillar_tree[conductor.region[:-1]]['management-vpc']

  if 'vpc' in kwargs:

    import boto.vpc
    conn = boto.vpc.connect_to_region(conductor.region[:-1])
    tags = conn.get_all_tags()

    if 'dte' == kwargs['vpc']:
      the_vpc = 'vpc.dte'
    else:
      the_vpc = 'vpc.{0}'.format(kwargs['vpc'])

    vpc_id = None

    if the_vpc == 'vpc.dte':
      dte_id = kwargs['dte']
      vpc_name = 'DTE-{0}-{1}'.format(conductor.pillarenv.upper(), dte_id)
    else:
      vpc_name = conductor.pillarenv.upper()
      if not vpc_name.lower() == the_vpc.split('.')[1].lower():
        logger.log('mis-matched pillarenv and vpc. cannot cross use these!', logger.state.error)
        return {}

    vpc_depends = {}
    for t in tags:
      if vpc_name == t.value:
        vpc_id = t.res_id
        
    for t in tags:
      #print 'value: ', t.value
      if vpc_name in t.value:
        vpc_depends[t.res_id] =  t.res_type

    
    if vpc_id:
      logger.log('about to destroy VPC {0} {1}'.format(vpc_name, vpc_id))

      confirm = raw_input("continue y/n?: ")
      if confirm.lower() == 'y':
        logger.log('ok, destroying.....')

        # REMOVE INSTANCE FIRST OFF
        from boto import ec2
        ec2_conn = boto.ec2.connect_to_region(conductor.region[:-1])

        try:
          to_be_removed = []
          instances = ec2_conn.get_only_instances(filters={"vpc_id": vpc_id})
          for i in instances:
            to_be_removed.append(str(i).split(':')[1])

          if to_be_removed:
            confirm = raw_input("There are instances attached to VPC dependencies, continue y/n?: ")
            if confirm.lower() == 'y':
              logger.log('ok, destroying.....')
              result = awsc.terminate_instances_wait(region=conductor.region[:-1], ids=to_be_removed)

        except Exception as e:
          logger.log('something happened trying to terminate vpc instances: {0}'.format(e), logger.state.warning)
          return {}
       
        # REMOVE SALT KEYS
        keys = []
        instance_map = awsc.get_aws_instance_map(awsconnector=conductor.AWS_CONNECT) 
        for i in to_be_removed:
          for m in instance_map:
            if i in m:
              logger.log('instance name: {0} {1}'.format( m[i], i))
              keys.append(m[i])
        if keys:
          results = conductor.delete_keys_from_list(keys) 
          logger.log('remove keys returned {0}'.format(results))
 

        # TERMINATED INSTANCES TAKE A SHORT TIME FOR AWS TO CLEAN UP ALL THE DEPENDENCY OBJECTS (THINGS WE DON'T KNOW ABOUT)
       
        for k,v in vpc_depends.iteritems():

          if v == 'route-table':
            try:
              if not conn.delete_route_table(route_table_id=k):
                logger.log('failed to delete route table {0}'.format(k), logger.state.error)
              else:
                logger.log('success delete route table {0}'.format(k))
            except Exception as e:
              logger.log('something happened trying to delete route or table: {0}'.format(e), logger.state.warning)

          if v == 'internet-gateway':
            try:
              if not conn.detach_internet_gateway(internet_gateway_id=k, vpc_id=vpc_id):
                logger.log('failed to detach inet gateway {0}'.format(k), logger.state.error)
              else:
                logger.log('success detach inet gateway {0}'.format(k))
                if not conn.delete_internet_gateway(internet_gateway_id=k):
                  logger.log('failed to delete inet gateway: {0}'.format(k), logger.state.error)
                else:
                  logger.log('success delete inet gateway: {0}'.format(k))
            except Exception as e:
              logger.log('something happened trying to delete inet gateway: {0}'.format(e), logger.state.warning)

          if v == 'subnet':
            try:
              if not conn.delete_subnet(subnet_id=k):
                logger.log('failed to delete subnet {0}'.format(k))
              else:
                logger.log('success delete subnet {0}'.format(k))
            except Exception as e:
              logger.log('something happened trying to delete subnet: {0}'.format(e), logger.state.warning)

          if v == 'security-group':
            try:
              if not ec2_conn.delete_security_group(group_id=k):
                logger.log('failed to delete security group {0}'.format(k), logger.state.error)
              else:
                logger.log('success delete security group {0}'.format(k))
            except Exception as e:
              logger.log('something happened trying to delete security group: {0}'.format(e), logger.state.warning)


        '''
        THE ABOVE ALL CAN BE DELETED BASED ON TAG SINCE WE CREATE THEM
        HOWEVER AWS CREATES DEPENDENCY OBJECTS AS WELL.
        NETWORK ACLS FOR VPC
        ROUTE TABLE (THE AUTOCREATED ONE) FOR VPC, etc..

        THERE ARE SOME CONSTRAINTS ON THESE PREVENTING THEM FROM BEING 
        REMOVED AND THUS A CHICK AND EGG SITUATION.
        CANNOT DELETE DEFAULT NETWORK ACL.
        CANNOT DELETE THE MAIN ROUTE TABLE FOR THE VPC.
    
        SO WE NEED TO TRY CATCH AND REMOVE THE ONES WE CAN. AND WHATEVER
        IS NOT ABLE TO DELETE, WILL GET REMOVED WHEN THE VPC GETS DELETED.

        THE ONLY OTHER THING PREVENTING DELETE VPC WOULD BE PEER CONNECTIONS.
        SO WE LOOK UP AND REMOVE THOSE, THEN VPC CAN BE DELETED.
        '''

        # NETWORK ACLS
        network_acls = conn.get_all_network_acls(filters={"vpc_id": vpc_id})
        for n in network_acls:
          try:
            if not conn.delete_network_acl(n.id):
              logger.log('failed to delete network acl {0}'.format(n.id), logger.state.error)
            else:
              logger.log('success delete network acl {0}'.format(n.id))
          except Exception as e:
            logger.log('something happened trying to delete network acl: {0}'.format(e), logger.state.warning) 
    
        # ROUTE TABLES (AND ROUTES)
        route_tables = conn.get_all_route_tables(filters={"vpc_id": vpc_id})
        for rt in route_tables:
          try:
            for x in rt.routes:
              _cidr = str(x).split(':')[1]
              if not conn.delete_route(rt.id, _cidr):
                logger.log('failled to delete route {0}'.format(_cidr), logger.state.error)
              else:
                logger.log('success delete route {0}'.format(_cidr))

            if not conn.delete_route_table(r.id):
              logger.log('failed to delete route table {0}'.format(r.id), logger.state.error)
            else:
              logger.log('success delete route table {0}'.format(r.id))
          except Exception as e:
            logger.log('something happened trying to delete route or table: {0}'.format(e), logger.state.warning)

        # VPC PEERING CONNECTIONS
        pcs = conn.get_all_vpc_peering_connections()
        for p in pcs:
          if vpc_id == str(p.requester_vpc_info).split(':')[1]:
            logger.log('remote peer {0}'.format(p.accepter_vpc_info))
            logger.log('this peer {0}'.format(p.requester_vpc_info))
            try:
              if not conn.delete_vpc_peering_connection(p.id):
                logger.log('failed to delete peering connection {0}'.format(p.id), logger.state.error)
              else:
                logger.log('success delete peering connection {0}'.format(p.id))
            except Exception as e:
              logger.log('something happened trying to delete a peer connection: {0}'.format(e), logger.state.warning)

        # THE VPC
        if not awsc.delete_vpc(region=conductor.region[:-1], vpcid=vpc_id):
          logger.log('failed to delete vpc {0}'.format(vpc_id), logger.state.error)

        return {}

      elif confirm.lower() == 'n':
        logger.log('canceling destroy action...\n')
        return {}

      else:
        logger.log('response is unrecognized. n or y', logger.state.error)
        return {}

  return {}


