'''
group.py
generic product group module
Conductor salt runner submodule
'''

from __future__ import absolute_import
import os, sys 
from collections import OrderedDict

from conductor import Conductor
from modules import conductor_common as cc

#sys.path.insert(0,'../..')
from common import aws as awsc
from common.utility import Logger
from common import utility as util

import urllib, urllib2
import simplejson as json 
import yaml 
import random
import inspect
import time 
from datetime import datetime, timedelta
import ast
from itertools import izip
 
# Import salt libs
import salt.pillar
import salt.utils.minions
import salt.client
import subprocess
import boto.ec2
import re

logger = Logger(shell=True)
preexisting_vms = []

conductor = None

def _load_product(the_group):
  from modules import load_product as lp 

  global conductor

  try:
    conductor = lp.load(the_group)
    conductor.productconf = conductor.PGROUP.Conf()
  except Exception as e:
    raise ValueError('failed to get conductor class') 

  return

# set aws module logger shell to true. we init this as false in common.aws
awsc.logger.shell = True

this_module = __name__.split('.')[1]

def _remove_salt_minion_keys():
  results = conductor.delete_keys(minion='*.{2}*.{0}.{1}.*'.format(conductor.pillarenv, conductor.region, this_module))
  return

def _upsize_help():
  '''
  docs
  '''

  message = '\nVALID FOR CLUSTER ROLES ONLY! ADD A MEMBER OR MEMBERS.\n\nrequired input:\n' + \
    '\tpillarenv=xxx\n' + \
    '\tregion=xxx\n' + \
    '\tgroup=product_group (product group defined in pillar/state model)\n' + \
    '\trole=roleid (product group cluster type role as defined in pillar/state model)\n' + \
    '\tclusterid=xx (valid product group cluster id, must exist as grain on at least one minion in the salt pillar environment)\n' + \
    '\noptional input:\n' + \
    '\tsaltenv=xxxxx (this will override the default of "release" salt environment)\n' + \
    '\tmembers=x (increase cluster member count  > 1 which is default)\n' + \
    '\ncommand line examples:\n' + \
    '\tsalt-run conduct.group upsize group=groupX role=clusterproductX pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group upsize group=groupX role=clusterproductX members=4 pillarenv=dev region=us-east-1b\n'

  print message

  return 

def upsize(**kwargs):

  if 'help' in kwargs:
    _upsize_help()
    return {}

  ''' check params '''
  if 'clusterid' not in kwargs:
    raise ValueError('Must specify clusterid param in resize action')
  if 'members' not in kwargs:
    kwargs['members'] = '1'  
  kwargs['resizing'] = True
  kwargs['action'] = 'upsize' 
  create(**kwargs)

def _downsize_help():
  '''
  docs
  '''

  message = '\nVALID FOR CLUSTER ROLES ONLY! REMOVE A MEMBER.\n\nrequired input:\n' + \
    '\tpillarenv=xxx\n' + \
    '\tregion=xxx\n' + \
    '\tgroup=product_group (product group defined in pillar/state model)\n' + \
    '\noptional input:\n' + \
    '\tsaltenv=xxxxx (this will override the default of "release" salt environment)\n' + \
    '\trole=roleid (REQUIRED unless node=xxx is specified, product group cluster type role as defined in pillar/state model)\n' + \
    '\tclusterid=xx (REQUIRED when using role=xxx, valid product group cluster id, must exist as grain on at least one minion in the salt pillar environment)\n' + \
    '\tnode=fqdn (specify exact instance to remove from cluster)\n' + \
    '\tinternal.role=internal_cluster_function (valid when not using node=xxx, defaults to secondary internal.role)\n' + \
    '\ncommand line examples:\n' + \
    '\tsalt-run conduct.group downsize group=groupX role=clusterproductX clusterid=2 pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group downsize group=groupX role=clusterproductX internalrole=secondary pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group downsize group=groupX role=clusterproductX internalrole=other pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group downsize group=groupX node=fqdn pillarenv=dev region=us-east-1b\n'

  print message

  return 


def downsize(**kwargs):

  if 'help' in kwargs:
    _downsize_help()
    return {}

  '''
  check params
  clusterid and role are not needed if node=xxx is specified in the arguments
  
  use node parameter when we need to remove a specific instance from a cluster
  use role, clusterid and optional internalrole when we need to simply downsize 
  its based on a cluster internal role, if internalrole is not passed, secondary is the default
  '''

  if 'grain' in kwargs:
    raise ValueError('grain is invalid parameter for downsize action.')
  if 'node' in kwargs:
    pass
  elif 'clusterid' not in kwargs or 'role' not in kwargs:
    raise ValueError('Must specify clusterid and role param in downsize action, or use node=xxx')
  else:
    pass

  if 'internalrole' not in kwargs and 'node' not in kwargs:
    kwargs['internalrole'] = 'secondary'

  kwargs['resizing'] = True
  kwargs['action'] = 'downsize'
  destroy(**kwargs)


def _create_help():
  '''
  docs
  '''

  message = '\nrequired input:\n' + \
    '\tpillarenv=xxx\n' + \
    '\tregion=xxx\n' + \
    '\tgroup=product_group (product group defined in pillar/state model)\n' + \
    '\trole=roleid (product group role as defined in pillar/state model)\n' + \
    '\noptional input:\n' + \
    '\tsaltenv=xxxxx (this will override the default of "release" salt environment)\n' + \
    '\tcount=x (REQUIRED but valid if role NOT set to all or role is a cluster)\n' + \
    '\tmembers=x (valid if role is cluster, increase or decrease new cluster member count from what is defined in provisioning pillar)\n' + \
    '\tsystem=systemname (product group specific system defined in product group config pillar, role is not valid when requesting a system)\n' + \
    '\tsysid=x (unique SYSTEMID, this is optional. when system=xxx is passed as well, next available system.id will be used if sysid value is not available)\n' + \
    '\tgrains={} (used to pass additional grains to create for a role. this if dynamic and should be used sparingly since there is no permanant record)\n' + \
    '\tshell=True|False (shell output on | off, default on)\n' + \
    '\tsandbox=xxxxx (used with cloud runner module only, not enabled at this point)\n' + \
    '\tvpcid=xxxx (used with cloud runner module only, not enabled at this point)\n' + \
    '\ncommand line examples:\n' + \
    '\tsalt-run conduct.group create group=groupX role=productX count=2 pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group create group=groupX role=productY members=4 pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group create group=groupX system=small_test pillarenv=dev region=us-east-1b\n' + \
    '\ncommands form the cloud module provisioning:\n' + \
    '\tdeploy to sandbox:\n' + \
    '\t  salt-run conduct.group create group=productgroup role=productX members=3 sandbox=sb1 pillarenv=dev region=us-east-1b\n' + \
    '\tdeploy to dte:\n' + \
    '\t  salt-run conduct.group create group=productgroup role=productX count=2 dte=1 pillarenv=dev region=us-east-1b\n\n'

  print message
  return 

def create(**kwargs):
  '''
  required input:
    pillarenv=xxx
    region=xxx
  
  other valid inputs:
    saltenv=xxxxx (this will override the default of "release"
    group=product_group
    role=roleid 
    count=x (only valid if role NOT set to all, not valid if role is cluster)
    members=x (only valid if role is cluster, if members is > than what is defined in pillar, any surplus is ignored. Pillar is the maximum)
    system=systemname (product group specific system, role is not valid when requesting a system)
    sysid=x (unique SYSTEMID, this is optional. when system= is passed as well, next available will be used otherwise. this will also be validated.)
    grains={} (used to pass additional grains for role)
    shell=True|False
    sandbox=xxxxx
    vpcid=xxxx
    overrides={} | filespec url can be http, https, url, uri
    statepillar={} | filespec url can be http, https, url, uri
 
  command line examples:
  salt-run conduct.group create group=pg1 role=core count=2 pillarenv=dev region=us-east-1b
  salt-run conduct.group create group=pg2 role=all pillarenv=dev region=us-east-1b
  deploy to sandbox
  salt-run conduct.group create group=productgroup role=all sandbox=foobar pillarenv=dev region=us-east-1b
  deploy to dte
  salt-run conduct.group create group=productgroup role=somerole count=1 dte=1 pillarenv=dev region=us-east-1b

  using pillar overrides (provisioning pillar)
  salt-run conduct.group create group=salty role=kafka count=1 pillarenv=test region=us-east-1a overrides='{"salty.role:test-overrides:level-one:setting-two": foobazzzzz}'
 
  using state pillar overrides (passed thru to salt states)
  salt-run conduct.group create group=salty role=kafka count=1 pillarenv=test region=us-east-1a overrides='{"salty.kafka": {"version": "confluent-4.0.0", "java-version": "1.8.0_181"}}'

  Use case: 
  When we need to spin up all machines to create a running environment in given pillarenv and saltenv with varying 
  configuration, use role=all
  If role=all then all nodes defined in templates/xxx.sls (in pillar) or whatever template declares these roles in the pillar tree will be created.
  The total number of each role that will be created is the nodes: x value in the template for the role.
  How the roles to be build are determined: the runner gets all roles from config.common, and checks for PRODUCTGROUP.role pillar and walks
  each roles' config, if role not found in the config, then it's assumed to be part of another product and its skip. 
  '''

  if 'help' in kwargs:
    _create_help()
    return {}

  if not 'group' in kwargs:
    print('group parameter required, abort!')
    return {}
  the_group = kwargs['group']

  _load_product(the_group)

  if not cc.initialize(conductor):
    return {}

  '''
  check for OVERRIDES kwarg BEFORE calling conductor.initialize()
  formats:
  Dict - overrides='{"one:two:foo:bar": XXX,"who:the:hell:is:this": 90}'  #you can also double quote the key and value. always quite string with :
  URL - overrides='https://git.com/raw/orgX/salt-state/test/common/consul/client/files/check_ro_mounts.json?token=AAAADm5CslvJiE7gv8AkTXsPimGB4mwpks5con6EwA%3D%3D'
        can be http, https, url, uri. THIS WOULD NEED TO BE ACCESSIBLE AND MUST BE IN JSON

  Nested Dict - salt-run conduct.group create group=salty role=kafka count=1 pillarenv=test region=us-east-1a overrides='{"level-one:level-two": {"key1": "30", "key2": "new stuff"}}'
  '''
  if 'overrides' in kwargs:
    if 'uri:' in (kwargs['overrides']) or \
         'url:' in (kwargs['overrides']) or \
         'http:' in (kwargs['overrides']) or \
         'https:' in (kwargs['overrides']):
      try:
        f = urllib.urlopen(kwargs['overrides'])
        _d = '\n'.join([i.strip() for i in f.readlines()])
        data = json.loads(_d)
        if data:
          #print 'user passed a file in JSON'
          kwargs['overrides'] = data
      except Exception as e:
        raise ValueError('failed to get url: {0}\n{1}'.format(kwargs['overrides'], e))
    elif isinstance(kwargs['overrides'], dict):
      pass
    elif isinstance(kwargs['overrides'], list):
      print 'List input type for overrides is not supported yet.'
      return {}
    else:
      print 'Unsupported input type for overrides', kwargs['overrides']
      return {}


  if not conductor.initialize(kwargs):
    print 'Conductor.initialize() failed. aws connector or pillar tree loading failed.'
    return {}

  print '\nNEW CLOUD PROVISION ID: {0}\n'.format(conductor.cpid)

  if conductor.debug:
    print conductor.pillarenv
    print conductor.opts
    print conductor.region
    print conductor.debug

  '''
  check for STATEPILLAR after calling conductor.initialize(). This is use to pass dynamic pillar through to the salt states.
  formats: Input must be a dictionary, will values of type Dict
  Dict - statepillar='{"NAME_OF_STATE": {"pillar1": "value1", "pillar2": "value2"}}'

  Examples:
  salt-run conduct.group create group=salty role=kafka count=1 pillarenv=test region=us-east-1a overrides='{"salty.kafka": {"version": "confluent-4.0.0", "java-version": "1.8.0_181"}}'
  salt-run conduct.group create group=salty role=kafka count=1 pillarenv=test region=us-east-1a overrides='{"salty.activemq": {"java-version": "1.8.0_181"}}'
  salt-run conduct.group create group=salty role=activemq count=1 pillarenv=test region=us-east-1a statepillar='{"salty.activemq": {"version": "5.15.5"}, "salty.dummy": {"version": "2.2.2"}}'

  In the above examples, the java-version pillar is actually passed twice. Example 2, conductor passes java-version pillar it to salty.activemq role state, 
  which in turn will set a local jinja variable that will be passed thru to the common.java state
  '''

  if 'statepillar' in kwargs:
    if 'uri:' in (kwargs['statepillar']) or \
         'url:' in (kwargs['statepillar']) or \
         'http:' in (kwargs['statepillar']) or \
         'https:' in (kwargs['statepillar']):
      try:
        f = urllib.urlopen(kwargs['statepillar'])
        _d = '\n'.join([i.strip() for i in f.readlines()])
        data = json.loads(_d)
        if data:
          kwargs['statepillar'] = util.convert_from_unicode(data)
      except Exception as e:
        raise ValueError('failed to get url: {0}\n{1}'.format(kwargs['statepillar'], e))
    else:
      if not isinstance(kwargs['statepillar'], dict):
        logger.log('statepillar argument MUST be type dict/json\n{0}'.format(type(kwargs['statepillar'])), logger.state.error)
        return {}

    conductor.STATE_PILLAR = kwargs['statepillar']
    logger.log('user passed in state pillar overrides\n{0}'.format(conductor.STATE_PILLAR))


  # commented out when implemented resizing clusters
  #if not util.verify_caller(this_module):
  #  logger.log('Cannot call submodules directly', logger.state.error)
  #  return{}

  # EXAMPLE USING DISCOVER
  '''
  data = {}
  data['role'] = 'somerole'
  data['product.group'] = the_group
  data['target'] = {"glob": "*.dev.*"}
  foo = cc.discover.service(conductor, data=data)
  print foo
  return {}
  '''

  the_role = None

  if 'sandbox' in kwargs:
    conductor.issandbox = True
    conductor.sandbox = kwargs['sandbox']

  if 'dte' in kwargs:
    conductor.dte = kwargs['dte']
    
  # verify passed in vpcid exists
  if 'vpcid' in kwargs:
    conductor.vpcid = kwargs['vpcid']
    if not awsc.vpcid_exists(region=conductor.region[:-1], vpcid=conductor.vpcid):
      logger.log('failed to locate vpcid, {0} vpc not found'.format(conductor.vpcid), logger.state.error)
      return {}

  if 'system' in kwargs:
    conductor.SYSTEMNAME = kwargs['system']
    conductor.issystem = True
  else:
    if not 'role' in kwargs:
      logger.log('role parameter required when not requesting system, abort!', logger.state.error)
      return {}
    the_role = kwargs['role']

  quantity = -1
  if 'count' in kwargs:
    quantity = kwargs['count']

  if not 'system' in kwargs:
    if not the_role == 'all' and quantity == -1 and not 'members' in kwargs:
      logger.log('if role parameter is NOT equal to all, count parameter must be greater than 0, abort!', logger.state.error)
      return {}
    logger.log('creating {0} {1}'.format(quantity, the_role))
  else:
    logger.log('creating system.{1}.{0}'.format(conductor.SYSTEMNAME, the_group))

  '''
  DETECT STALE VM'S RENAME IF TERMINATED.
  CAN FILTER ON NAME OR NEW GRAIN product.group 
  '''
  _filter = '.{0}.{1}.'.format(conductor.region, conductor.pillarenv)
  _vms = [] 
  for i in awsc.get_aws_instance_map(awsconnector=conductor.AWS_CONNECT):
    if i:
      for k,v in i.iteritems():
        if _filter in str(v):
          _vms.append(i)
  rename_vms = [] 
  for vm in _vms:
    for k,v in vm.iteritems():
      status = awsc.get_instance_status(awsconnector=conductor.AWS_CONNECT, id=k)
      if status == 'terminated': 
        rename_vms.append(vm)
  print '{0} terminated instances...\n'.format(len(rename_vms)), rename_vms

  for vm in rename_vms:
    for k,v in vm.iteritems():
      id_list = str(k).split()
      tags = {'Name': 'renamed_{0}'.format(str(random.getrandbits(32)))}
      test = awsc.create_instance_tag(awsconnector=conductor.AWS_CONNECT, ids=id_list, tags=tags)
      if not test:
        logger.log('failed to rename terminated vm {0}'.format(v))
      else:
        print 'success renaming {0}'.format(v)


  # THIS RETURNS ALL INSTANCE IN THE REGION REGARDLESS OF AZ
  for i in awsc.get_aws_instance_map(awsconnector=conductor.AWS_CONNECT):
    if i:
      for k,v in i.iteritems():
        preexisting_vms.append(str(v))
  if conductor.debug:
    print 'all existing instances\n', preexisting_vms


  logger.log('creating {0} nodes.....'.format(this_module))
 
  # VERIFY SOME REQUIRED PILLAR DATA
  if not 'config.common' in conductor.pillar_tree:
    logger.log('Cannot find config.common pillar data, make sure your pillar is in environment {0}'.format(conductor.pillarenv), logger.state.error)
    return {}

  if not '{0}.role'.format(conductor.product.lower()) in conductor.pillar_tree:
    logger.log('Cannot find {0}.role pillar data, make sure your pillar is in environment {1}'.format(conductor.product.lower(), conductor.pillarenv))
    print conductor.pillar_tree
    return {}


  # CHECK ANYTHING ELSE THAT MIGHT BE NEEDED PRIOR TO RUNNING SALT STATE. 
  # EXAMPLE, IF CREATING A DB CLUSTER AND THE CLUSTER NEEDS TO BE INITIALIZED AND USES GRAINS
  # TO TELL MEMBERS ABOUT THE OTHER MEMBERS, THEN WE MIGHT NEED TO CHECK PILLAR BEFORE PROVISIONING

  if conductor.SYSTEMNAME:
    if not 'system.{0}'.format(conductor.product.lower()) in conductor.pillar_tree:
      logger.log('Cannot find system.{0} pillar data, make sure your pillar is in environment {1}'.format(conductor.product.lower(), conductor.pillarenv))
      return {}
    if not '{0}.system.{1}'.format(conductor.product.lower(), conductor.SYSTEMNAME) in conductor.pillar_tree['system.{0}'.format(conductor.product.lower())]:
      logger.log('Cannot find system.{0} pillar data, make sure your pillar is in environment {1}'.format(conductor.product.lower(), conductor.pillarenv))
      return {}

    group_system_pillar = conductor.pillar_tree['system.{0}'.format(conductor.product.lower())]
    system_pillar = group_system_pillar['{0}.system.{1}'.format(conductor.product.lower(), conductor.SYSTEMNAME)]

    if not isinstance(system_pillar, dict):
      print 'wrong yaml type for system'
      return {}

    all_system_roles = []
    for k,v in system_pillar.iteritems():
      all_system_roles.append({util.convert_from_unicode(k): util.convert_from_unicode(v)})

    # SET A PRODUCT GROUP SYSTEM ID USED FOR GRAIN TARGETING
    if not 'sysid' in kwargs:
      sysid_available = False
      while not sysid_available:
        sysid_available, theid = cc.next_systemid(conductor, True, minion='G@{0}.system.id:*'.format(conductor.product.lower()))
        if sysid_available:
          conductor.SYSTEMID = theid
          break
    else:
      # verify that the requested GROUP sysid does not already exist
      if not (cc.available_systemid(conductor, True, kwargs['sysid'], minion='G@{0}.system.id:*'.format(conductor.product.lower()))):
        logger.log('The sysid you requested already exists in the salt environment {0} for {1}\nTry again.'.format(conductor.env, conductor.product.lower()))
        return {}
      conductor.SYSTEMID = kwargs['sysid']

    # SET A UNIQUE CLOUD SYSTEM ID USED FOR GRAIN TARGETING
    sysid_available = False
    while not sysid_available:
      sysid_available, theid = cc.next_systemid(conductor, False, minion='G@cloud.system.id:*')
      if sysid_available:
        conductor.CLOUDSYSTEMID = theid
        break
    
  if 'grains' in kwargs:
    conductor.GRAINS = kwargs['grains']

  if 'domain_suffix' in conductor.pillar_tree['global']:
    conductor.nodename_suffix = conductor.pillar_tree['global']['domain_suffix']


  # IF RESIZING (A CLUSTER) VERIFY ID, AND SET IN CONDUCTOR CLASS
  if 'resizing' in kwargs and kwargs['resizing'] and 'action' in kwargs and (kwargs['action'] == 'upsize'): 
    exists, cloudid, members = cc.verify_resize_cluster_id(conductor, the_role, int(kwargs['clusterid']))
    if not exists:
      print 'clusterid {0} not found for resizing, abort'.format(kwargs['clusterid'])
      return {}

    # SET GLOBAL VALUES IN MAIN CLASS
    conductor.RESIZING = True
    conductor.RESIZEID = int(kwargs['clusterid'])
    conductor.RESIZE_CLOUDID = cloudid
    conductor.RESIZE_CLUSTER_MEMBERS = members

    logger.log('{4}.{2}.cluster.id {0} exists with members\n{1}\ncloud.{2}.cluster.id={3}\n'.format( conductor.RESIZEID, \
                                                                                                     members, \
                                                                                                     the_role, \
                                                                                                     conductor.RESIZE_CLOUDID, \
                                                                                                     conductor.product.lower()))

    '''
    note: we do not get the cluster.members.ip grain. Its best to do this after the new vm is complete to assure we
    get an up to date grain value in the event more than one conductor process was upsizing the same cluster.
    so we should re-query for cluster.members as well when new vm is done. Can use only one member from this list, and iterate the list
    if that member fails to return results.
    '''

  # SUPPORTED ROLES AND ROLES THAT WE WANT TO CREATE
  roles = conductor.pillar_tree['config.common']['roles']
 
  all_roles = roles
  if conductor.SYSTEMNAME:
    all_roles = all_system_roles
    the_role = 'all'

  product_roles = conductor.pillar_tree['{0}.role'.format(conductor.product.lower())]['all']

  if the_role == 'all':

    components = []

    for _therole in all_roles:
      args_holder = kwargs
      if conductor.SYSTEMNAME:
        role = _therole.iteritems().next()[0]
        if _therole.iteritems().next()[1].iteritems().next()[0].lower() == 'members':
          if not _therole.iteritems().next()[1].iteritems().next()[1] == 'default':
            args_holder['members'] = _therole.iteritems().next()[1].iteritems().next()[1]
        if _therole.iteritems().next()[1].iteritems().next()[0].lower() == 'count':
          if not _therole.iteritems().next()[1].iteritems().next()[1] == 'default':
            args_holder['count'] = _therole.iteritems().next()[1].iteritems().next()[1]
      else:
        role = _therole 
        args_holder = kwargs


      print 'configuring THE ROLE {0}'.format(_therole)

      if (( role in product_roles) or ('composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), role)])):
        components_ = []
        conductor.building_roles.append(role)

        print '\nconfiguring THE ROLE {0}'.format(role)
       
        if 'count' in args_holder:
          components_ = cc.create_prebuild_object(conductor, role, int(args_holder['count']), **args_holder)
        else:
          if 'members' in args_holder:
            components_ = cc.create_prebuild_object(conductor, role, int(args_holder['members']), **args_holder)
          else:
            components_ = cc.create_prebuild_object(conductor, role, -1, **args_holder)
        if not components_:
          logger.log('Failed to construct new vm component, abort.', logger.state.error)
          return {}

        # just need to check the first element. if elements are > 1, it's a cluster and they all will be the same except internalrole  
        if components_[0]['nodes'] > 0 and \
           components_[0]['pattern'] and \
           components_[0]['role'] and components_[0]['size']:

          if components_:
            for comp in components_:
              components.append(comp)
   
    result = cc.create_cloud_config(conductor, components, existing_nodes=preexisting_vms)
    if not result:
      logger.log('Failed to update Prebuild component in new_cloud_build_xtra', logger.state.warning)

  else:
    print 'Creating ', the_role, quantity

    conductor.building_roles.append(the_role)
     
    print the_role
    print product_roles

    if (( the_role in product_roles) or ('composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), the_role)])):

      components = [] # make list in case the_role is a cluster
      components = cc.create_prebuild_object(conductor, the_role, quantity, **kwargs)
      if not components:
        logger.log('Failed to construct new vm component, abort.', logger.state.error)
        return {}
      # just need to check the first element. if elements are > 1, it's a cluster and they all will be the same except internalrole  
      if components[0]['nodes'] > 0 and \
         components[0]['pattern'] and \
         components[0]['role'] and components[0]['size']:
        result = cc.create_cloud_config(conductor, components, existing_nodes=preexisting_vms)
        if not result:
          logger.log('Failed to update Prebuild component in new_cloud_build_xtra', logger.state.warning)


  # GET VPC IF NOT SET IN PARAMS
  if not conductor.vpcid:
    conductor.vpcid = conductor.pillar_tree['{0}'.format(conductor.region[:-1])]['vpc']

  # SEC GROUP SHOULD BE ID
  mgmt_secgrp, public_secgrp, private_secgrp = cc.get_default_security_groups(conductor)
  if not mgmt_secgrp:
    logger.log('critical, cannot find management securitygroupId in pillar, aborting.', logger.state.error)
    return {}

  '''
  IF WE WERE CREATING CUSTOM GROUPS FOR THE NEW VM'S, ADD IT HERE
  GET RULES FROM PILLAR
  CREATE SEC GROUP, GET SEC GROUP ID FROM AWS RETURN
  ADD TO ANY VM'S THAT ARE GOING IN THAT GROUP
  '''

  public_subnet, private_subnet = cc.get_default_subnets(conductor)
  if not public_subnet or not private_subnet:
    logger.log('failed to find default environment public/private subnet and/or security group', logger.state.error)

  # CHECK FOR OVERRIDE OF SUBNETS AND SEC GROUPS 
  result, public_secgrp, private_secgrp, public_subnet, private_subnet = cc.check_infrastructure_overrides(conductor, \
                                                                   public_secgrp=public_secgrp, \
                                                                   private_secgrp=private_secgrp, \
                                                                   public_subnet=public_subnet, \
                                                                   private_subnet=private_subnet)

  if not result:
    logger.log('aborting, see logs for details...', logger.state.error)
    return {}

  # name the new cloud map 
  config_name = '{0}-create'.format(this_module)

  # TODO: not sure what the final outcome, but we hard set PUBLIC secgroup and subnet in cloud profile/provider
  if not conductor.create_profile_provider_conf(cc.construct_conf_inputs(conductor, \
                                                                         logger, \
                                                                         name=config_name, \
                                                                         subnet=public_subnet, \
                                                                         secgroup=public_secgrp)):

    logger.log('Failed to create profile and provider conf, abort.', logger.state.error)
    return {}

  # THIS DICT IS USED AS DEFAULTS WHEN THE ROLE IS NOT SPECIFYING AN OVERRIDE FOR SUBNET/SECURITY GROUP TYPE
  networking = {}
  networking['public-subnet'] = public_subnet
  networking['private-subnet'] = private_subnet
  networking['public-security-group'] = public_secgrp
  networking['private-security-group'] = private_secgrp

  # CREATE CLOUD MAP 
  if 'persist-volumes' in conductor.pillar_tree['config.common']:
    if str(conductor.pillar_tree['config.common']['persist-volumes']).lower() == "true":
      new_cloud_map = cc.create_map(conductor, logger, config_name, True, networking)
    else:
      new_cloud_map = cc.create_map(conductor, logger, config_name, False, networking)
  else:
    new_cloud_map = cc.create_map(conductor, logger, config_name, False, networking)   

  if not new_cloud_map:
    logger.log('Failed to create cloud map, abort', logger.state.error)
    return {}

  # not really using this yet
  all_minion_target = '*.{0}.{1}.*'.format(conductor.region, conductor.pillarenv)

  # minion_target is used to pass node list into conductor_common.build_cloud in case a failure
  # also for running sync_modules
  # we use this minion_target as the filter to delete_keys since salt would have already created them
  minion_target = []



  for i in conductor.PGROUP.new_cloud_build_xtra:
    for k,v in i.iteritems():
      for n in v['names']:
        minion_target.append(n)
        print '....building', n


  minion_target = list(set(minion_target))  

  '''
  print "1st exit early for map create testing"
  return {}
  '''

  ''' ---------------------------- PRE PROVISION HOOKS (these hook do NOT use grains) -----------------------------'''

  '''
  HOOK (common) PRE PROVISION ORCHESTRATION (pillar://config/common.sls, config.common:hooks:pre-provision-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target)
  _pillars['cpid'] = conductor.cpid
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'pre-provision-orchestration', conductor.pillar_tree['config.common'], _pillars)

  '''
  HOOK (group) PRE PROVISION ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:hooks:pre-provision-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target)
  _pillars['product-group'] = conductor.product.lower()
  _pillars['cpid'] = conductor.cpid
  _pillars['resizing'] = conductor.RESIZING
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'pre-provision-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())], _pillars)

  '''
  HOOK (role) PRE PROVISION ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:pre-provision-orchestration)
  '''
  unique_roles = list(set(conductor.building_roles))
  for r in unique_roles:
    _targets = []
    for i in conductor.PGROUP.new_cloud_build_xtra:
      for k,v in i.iteritems():
        if '{0}.{1}'.format(conductor.product.lower(),r) == v['role']: 
          for n in v['names']:
            _targets.append(n)

    if _targets:
      _targets = list(set(_targets))  
      print 'checking hooks for role:', r
      _pillars = {}
      _pillars['target-minion'] = ','.join(_targets)
      _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
      if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
      _pillars['cpid'] = conductor.cpid
      _pillars['resizing'] = conductor.RESIZING
      _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)

      if not 'composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        cc.hook_check(conductor, 'pre-provision-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)
      else:
        _states = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['composite.role']
        if _states:
          for rs in _states:
            if not rs.split('.')[1] in unique_roles:
              cc.hook_check(conductor, 'pre-provision-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][rs.split('.')[1]], _pillars)

  '''
  print '\nEND PILLAR', conductor.pillar_tree['salty.role']['kafka']
  print "exit early for pre hook and map create testing"
  for r in conductor.id_reservations:
    try:
      print 'removing', r
      os.remove(r)
    except Exception as e:
      logger.log('failed to remove reserved id file {0}'.format(r), logger.state.warning)
  for n in conductor.name_reservations:
    try:
      print 'removing', n
      os.remove(n)
    except Exception as e:
      logger.log('failed to remove reserved name file {0}'.format(n), logger.state.warning)
  return {}
  '''



  '''
  BUILD ALL INSTANCES
  '''

  #START BLOCK

  confdata = conductor.build_cloud(configname=config_name, \
                                 target=minion_target, \
                                 expected_nodes=conductor.productconf.all_nodes, \
                                 cloudmap=new_cloud_map)

  # REMOVE RESERVED ID'S HERE NOW THAT THE MINIONS ARE UP
  for r in conductor.id_reservations:
    try:
      print 'removing reservation', r
      os.remove(r)
    except Exception as e:
      logger.log('failed to remove reserved id file {0}'.format(r), logger.state.warning)
  for n in conductor.name_reservations:
    try:
      print 'removing reservation', n
      os.remove(n)
    except Exception as e:
      logger.log('failed to remove reserved name file {0}'.format(n), logger.state.warning)

  if not confdata:
    print 'Something failed in creating new vms, aborting.'
    logger.log('Something failed in creating new vms, aborting.', logger.state.error)
    return {}


  # TAG ROOT VOLUMES WITH Name:nodename, ProvisionID:cpid

  #for anything defined in our config block-volume, we are using PR-48716 saltstack feature 
  #Conductor model also supports root-volume-tags in our config for setting tags on the root volume
  #when not specifying block-volume.
  #if root-volume-tags is not defined, we still set 'Name' tag to the instance hostname.
  #if block-volume is defined and the root device is not one of the entries, this default 'Name' will
  #catch things from having no tags at all.
 
  instance_id_name_map = awsc.get_aws_instance_map(awsconnector=conductor.AWS_CONNECT)
  new_instance_map = []  #only what we just created
  for i in instance_id_name_map:
    if i:
      if i.values()[0] in conductor.productconf.all_nodes:
        new_instance_map.append(i)

  result, _instances = awsc.get_aws_instances(awsconnector=conductor.AWS_CONNECT)
  for i in _instances:
    for n in new_instance_map:
      rootvol_tags = {}
      volumeID = None
      if n.keys()[0] == i.__dict__['id']: 
        for voltype, devtype in i.__dict__['block_device_mapping'].iteritems():
          if voltype == i.__dict__['root_device_name']:
            volumeID = str(devtype.__dict__['volume_id'])
            if n.values()[0] in conductor.productconf.root_volume_tags:
              rootvol_tags['Name'] = n.values()[0]
              rootvol_tags['ProvisionID'] = '\"{0}\"'.format(str(conductor.cpid))
              for k,v in conductor.productconf.root_volume_tags[n.values()[0]].iteritems():
                rootvol_tags[k] = v
        if volumeID and rootvol_tags:
          logger.log('ADDING ROOT VOLUME {0} TAGS......'.format(volumeID), logger.state.info)
          ret = conductor.AWS_CONNECT.create_tags([volumeID], rootvol_tags, False)
          print ret

  #END BLOCK


  print 'RETURNED AWS CLOUD DATA\n'
  print confdata
  


  #print 'exit early before startup states for testing.....'
  #return {}

 
  # TODO: ELB stuff, use public sec and subnet for testing
  # if elbv2, subnets must be minimum 2
  #result = cc.check_load_balancer_data(conductor, security_group_id=public_secgrp, subnets=public_subnet.split())

  _subnets = []
  _subnets.append(private_subnet)
  _subnets.append('subnet-086c7450') #hardcoded for elbv2 testing, two subnets must be in different zones
  result = cc.check_load_balancer_data(conductor, security_group_id=public_secgrp, subnets=_subnets)

 
  # SYNC MODULES. IN PAST SALT VERSIONS, CUSTOM MODULES WERE NOT RECOGNIZED WHEN SALT FIRST STARTED ON MINIONS.
  if not conductor.sync_modules(target=minion_target):
    logger.log('saltutil.sync_modules returned false, custom _modules may need to be synced on minions', logger.state.error)


  ''' 
  UPSIZING
  If action is upsize, we need to query at least one instance in conductor.RESIZE_CLUSTER_MEMBERS to get the updated
  list of members (could have changed if another upsize or downsize was running on the same cluster). Then add the 
  member list to all new members just provisioned. Do this before creating the cluster.members.ip grain
  '''
  
  all_members = minion_target #default

  if conductor.RESIZEID:
    members_updated = False
    while not members_updated and len(conductor.RESIZE_CLUSTER_MEMBERS) > 0:
      for m in conductor.RESIZE_CLUSTER_MEMBERS: 
        exists, cloudid, members = cc.verify_resize_cluster_id(conductor, the_role, int(kwargs['clusterid']), minion=m)
        if members:
          for _m in minion_target:
            logger.log('update pre existing members with {0}'.format(_m), logger.state.info)
            conductor._append_grains_list(','.join(members), 'cluster.members', _m)

          members.extend(minion_target)

          for cm in members:
            logger.log('update new minions with {0}'.format(cm), logger.state.info)
            conductor._append_grains_list(','.join(minion_target), 'cluster.members', cm)
          members_updated = True
          all_members = members
          break


  '''
  CHECK GRAINS FOR cluster.members. IF EXIST, CREATE cluster.members.ip ON ALL INSTANCES THAT HAVE cluster.members USING THE HOST NAMES TO GET IP FOR EACH.
  DESCRIPTION: SOME CLUSTERED INSTANCES NEED TO KNOW EACH MEMBERS IPADDR (THERE SHOULD ALREADY BE A cluster.members grain THAT WILL BE DNS MACHINE NAMES ONLY).
  COULD OPTIONALLY NOT DO THIS IN ORCHESTRATE STATE, BUT WOULD LOOSE THE ABILITY TO QUERY ALL CLUSTER MINIONS (SINCE STATES RUN ON MINION).
  WE WOULD HAVE TO HAVE A SALT STATE EXECUTION TO DO THIS. MAKES MORE SENSE TO DO IT HERE REGARDLESS OF WHAT MAY OR MAY NOT NEED IT.
  '''
  print time.asctime( time.localtime(time.time()) ), 'update cluster.members.ip grains'

  for n in all_members:
    print 'get grain on', n
    ret = conductor.get_grain_value(n, 'cluster.members')
    if ret:
      for cm in ret:
        print 'getting ipv4 from', cm
        _ip = conductor.get_grain_value(cm, 'ipv4')
        print 'ipv4 results', type(_ip), _ip
        if _ip and _ip[0]:
          conductor._append_grain(n, 'cluster.members.ip', _ip[0])
        else:
          logger.log('problem with ipv4 index {0}'.format(_ip[0]), logger.state.error)


  ''' ***** ADDING CLUSTER.MEMBERS.INFO NESTED DICTIONARY GRAINS ***** '''
  # TODO maybe can remove the cluster.members and cluster.members.ip grains in favor of cluster.members.info. However, may be easier in states to have the option
  # to just use them.

  for n in all_members:
    ret = conductor.get_grain_value(n, 'cluster.members')
    if ret:

      _vals = {}

      for cm in ret:
        _ip = conductor.get_grain_value(cm, 'ipv4')
        _mid = conductor.get_grain_value(cm, 'cluster.member.id')

        if _ip and _ip[0] and _mid:
          _vals[cm] = {'ip': _ip[0], 'member_id': _mid}
 
      if _vals:
        conductor._create_nested_grain(n, 'cluster.members.info', _vals)


  print time.asctime( time.localtime(time.time()) ), 'done updating cluster.members.info grains'


  ''' **** PROCESS ROLE DISCOVERY REQUIREMENTS '''
  unique_roles = list(set(conductor.building_roles))
  for r in unique_roles:
    _process_role_discovery(r, _targets)


  ''' ---------------------------- PRE UPSIZE HOOKS - THESE ARE AVAILABLE AS ROLE BASED HOOKS. I.E. NO GROUP OR ENV SCOPE -----------------------------'''
 
  '''
  HOOK (role) PRE UPSIZE (CLUSTER ROLES ONLY) ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:pre-upsize-orchestration)
  '''
  if conductor.RESIZEID:
    unique_roles = list(set(conductor.building_roles))
    for r in unique_roles:
      print 'checking pre-upsize hooks for role:', r
      _pillars = {}
      _pillars['target-minion'] = ','.join(minion_target)
      _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
      if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
      _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
      _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
      cc.hook_check(conductor, 'pre-upsize-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)


  ''' ---------------------------- PRE STARTUP HOOKS  -----------------------------'''

  '''
  HOOK (common) PRE startup_state ORCHESTRATION (pillar://config/common.sls, config.common:hooks:pre-startup-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target)
  _pillars['cpid'] = conductor.cpid
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'pre-startup-orchestration', conductor.pillar_tree['config.common'], _pillars)


  '''
  HOOK (group) PRE startup_state ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:hooks:pre-startup-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target)
  _pillars['product-group'] = conductor.product.lower()
  _pillars['cpid'] = conductor.cpid
  _pillars['resizing'] = conductor.RESIZING
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'pre-startup-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())], _pillars)


  '''
  HOOK (role) PRE startup_state ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:pre-startup-orchestration)
  '''
  unique_roles = list(set(conductor.building_roles))
  for r in unique_roles:
    _targets = []
    for i in conductor.PGROUP.new_cloud_build_xtra:
      for k,v in i.iteritems():
        if '{0}.{1}'.format(conductor.product.lower(),r) == v['role']: 
          for n in v['names']:
            _targets.append(n)

    if _targets:
      _targets = list(set(_targets))  
      print 'checking pre startup state hooks for role:', r
      _pillars = {}
      _pillars['target-minion'] = ','.join(_targets)
      _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
      if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
      _pillars['cpid'] = conductor.cpid
      _pillars['resizing'] = conductor.RESIZING
      _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)

    if not 'composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
      cc.hook_check(conductor, 'pre-startup-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)
    else:
      _states = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['composite.role']
      if _states:
        for rs in _states:
          if not rs.split('.')[1] in unique_roles:
            cc.hook_check(conductor, 'pre-startup-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][rs.split('.')[1]], _pillars)


  '''
  HOOK (role) DELAYED STATES
  SALT MINION startup_states GET DELAYED DUE TO THE SYNC MODULES ISSUE THIS CODE EVALUATES THAT FLAG AND EXECUTES THE startup_states ON NEW INSTANCES
  '''
  if conductor.productconf.delaystates:
    print 'delayed states detected...'
    logger.log('startup state run delayed')
    state_node_map = {} 
    for rs in conductor.productconf.delaystates:
      if isinstance(rs, dict):
        for n,s in rs.items():
          state_str = ','.join(s) #lists are not hashable, so convert state list to string
          if state_str in state_node_map:
            val = state_node_map[state_str]
            val.append(n)
            state_node_map.update({state_str:val})
          else:
            state_node_map[state_str] = n.split()
    for s,nlist in state_node_map.items():
      nodes = ','.join(nlist) #convert nodes list to string

      if conductor.STATE_PILLAR:
        _statelist = s.split(',') # convert states string back to list when user passes in state specific pillar overrides
        logger.log('USER SPECIFIED STATE PILLAR, run states asyncronously!', logger.state.warning)
      else:
        _statelist = s.split() #this will be string 
        logger.log('NO state pillar overrides passed in, so run states syncronously!', logger.state.info)

      logger.log('running startup states {0} for {1}'.format(s,nodes))
      if not conductor.run_startup_states(target=nodes,run_state=_statelist):
        logger.log('Startup state {0} on node {1} may not have run, please verify'.format(_statelist, nodes), logger.state.warning)
  else:
    print 'no delayed states...'  



  ''' ---------------------------- POST UPSIZE HOOKS (THESE ARE AVAILABLE AS ROLE BASED HOOKS. I.E. NO GROUP OR ENV SCOPE -----------------------------'''
  '''
  HOOK (role) POST UPSIZE (CLUSTER ROLES ONLY) ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:post-upsize-orchestration)
  '''
  if conductor.RESIZEID:
    unique_roles = list(set(conductor.building_roles))
    for r in unique_roles:
      print 'checking post upsize hooks for role:', r
      _pillars = {}
      _pillars['target-minion'] = ','.join(minion_target)
      _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
      if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
      _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
      _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
      cc.hook_check(conductor, 'post-upsize-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)



  ''' ---------------------------- POST STARTUP HOOKS -----------------------------'''

  '''
  HOOK (common) POST startup_state ORCHESTRATION (pillar://config/common.sls, config.common:hooks:post-startup-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target)
  _pillars['cpid'] = conductor.cpid
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'post-startup-orchestration', conductor.pillar_tree['config.common'], _pillars)


  '''
  HOOK (group) POST startup_state ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:hooks:post-startup-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target)
  _pillars['product-group'] = conductor.product.lower()
  _pillars['cpid'] = conductor.cpid
  _pillars['resizing'] = conductor.RESIZING
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'post-startup-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())], _pillars)
  

  '''
  HOOK (role) POST startup_state ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:post-startup-orchestration)
  '''
  unique_roles = list(set(conductor.building_roles))
  for r in unique_roles:
    _targets = []
    for i in conductor.PGROUP.new_cloud_build_xtra:
      for k,v in i.iteritems():
        if '{0}.{1}'.format(conductor.product.lower(),r) == v['role']: 
          for n in v['names']:
            _targets.append(n)

    if _targets:
      _targets = list(set(_targets))  
      print 'checking post startup state hooks for role:', r
      _pillars = {}
      _pillars['target-minion'] = ','.join(_targets)
      _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
      if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
      _pillars['cpid'] = conductor.cpid
      _pillars['resizing'] = conductor.RESIZING
      _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)

    if not 'composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
      cc.hook_check(conductor, 'post-startup-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)
    else:
      _states = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['composite.role']
      if _states:
        for rs in _states:
          if not rs.split('.')[1] in unique_roles:
            cc.hook_check(conductor, 'post-startup-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][rs.split('.')[1]], _pillars)

  print '\nNEW CLOUD PROVISION ID: {0}\n'.format(conductor.cpid)

  return True


def _create(cmdargs):
  '''
  do the work here
  '''


def _destroy_help():
  '''
  docs
  '''

  message = '\nrequired input:\n' + \
    '\tpillarenv=xxx\n' + \
    '\tregion=xxx\n' + \
    '\tgroup=product_group (product group defined in pillar/state model)\n' + \
    '\trole=roleid (product group role as defined in pillar/state model)\n' + \
    '\noptional input:\n' + \
    '\tsaltenv=xxxxx (this will override the default of "release" salt environment)\n' + \
    '\tgroup=product_group (valid product group defined in pillar/state model)\n' + \
    '\n\tonly one of the following:\n' + \
    '\trole=product (the product group product/roleid defined in pillar/state model)\n' + \
    '\tor\n' + \
    '\tnode=nodename (this is a string match of fqdn host name, the ID salt grains that saltmaster uses)\n' + \
    '\tor\n' + \
    '\tgrain=\'{k: v}\' (must be a supported grain as defined in the conductor framework docs)\n' + \
    '\n\tshell=True|False (enable or disable shell output)\n' + \
    '\ncommand line example:\n' + \
    '\tsalt-run conduct.group destroy group=productgroup role=group.role pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group destroy group=productgroup node=my-web-server-1 pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group destroy group=productgroup grain=\'{\"cpid\": 178581258125815}\' pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group destroy group=productgroup grain=\'{\"mygroup.productX.cluster.id\": 2}\' pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group destroy group=productgroup grain=\'{\"mygroup.system.id\": 1}\' pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group destroy group=productgroup grain=\'{\"cloud.productX.cluster.id\": 178581258125815}\' pillarenv=dev region=us-east-1b\n' + \
    '\tsalt-run conduct.group destroy group=productgroup grain=\'{\"cloud.system.id\": 12}\' pillarenv=dev region=us-east-1b\n'

  print message

  return 

def destroy(**kwargs):
  '''
  use case for when we need to destroy an instance for the product group
  reference:

  required input:
    pillarenv=xxx
    region=xxx
  
  other valid inputs:
    saltenv=xxxxx (this will override the default of "release"
    group=product_group
    role=roleid|all [if all is specified, all roles nodes hosting any role in the product group will be destroyed] 
    or 
    node=nodename
    or 
    grain='{k: v}' 
    shell=True|False
    if downsizing, clusterid is required and either node=xxx or internalerole=xxxxx

  command line example:

  salt-run conduct.group destroy group=productgroup role=group.role pillarenv=dev region=us-east-1b

  '''

  if 'help' in kwargs:
    _destroy_help()
    return {}

  the_group = None
  if not 'group' in kwargs:
    print('group parameter required, abort!')
    return {}
  the_group = kwargs['group']

  _load_product(the_group)

  if not cc.initialize(conductor):
    return {}

  if not conductor.initialize(kwargs):
    print 'initialize() failed. aws connector or pillar tree loading failed.'
    return {}

  # commented when downsize was implemented
  #if not util.verify_caller(this_module):
  #  logger.log('Cannot call submodules directly', logger.state.error)
  #  return{}

  the_role = None
  the_grain = {}

  print '\nNEW CLOUD PROVISION ID {0}\n'.format(conductor.cpid)

  if 'action' in kwargs and kwargs['action'] == 'downsize':
    conductor.RESIZING = True
    pass

  else:
    if not 'role' in kwargs and not 'node' in kwargs and not 'grain' in kwargs:
      logger.log('grain, role or node parameter required, abort!', logger.state.error)
      return {}
    if 'role' in kwargs and 'node' in kwargs:
      logger.log('role or node parameter required, pick one only!', logger.state.error)
      return {}
    _invalid_args = False
    if 'grain' in kwargs and ('role' in kwargs or 'node' in kwargs):
      _invalid_args = True
    elif 'role' in kwargs and ('grain' in kwargs or 'node' in kwargs):
      _invalid_args = True
    elif 'node' in kwargs and ('grain' in kwargs or 'role' in kwargs):
      _invalid_args = True
    else:
      pass
    if _invalid_args:
      logger.log('grain, role or node parameter required, pick one only!', logger.state.error)
      return {}

  # FIRST THING TO DO IS GET MINION LIST OF INSTANCES THAT ARE DESTROYABLE 
  # THEY ARE DESTROYABLE IF THEY HAVE A MATCHING product.group GRAIN VALUE AND MATCHING
  # EITHER instance name, role or other supported grains such as cpid, cluster.id, system.id etc....

  minion_target = {}
  minion_target = cc.get_destroyable_instances(kwargs, conductor)

  if not minion_target:
    print 'Nothing to destroy with given command'
    return {}

  # if downsizing should only be one instance here
  if 'action' in kwargs and kwargs['action'] == 'downsize' and (len(minion_target) > 1):
    logger.log('Only one instance can be downsized in a cluster', logger.state.error)
    return {}

  minion_target_names = [v for k,v in minion_target.iteritems()]

  # NEED TO GET CLUSTERIDand ROLE GRAIN EVEN IN THE CASE WHERE IS WAS NOT ON CMDLINE (I.E. downsizing by node)
  _role = conductor.get_grain_value(minion_target_names[0], 'role')
  if _role:
    if '.' in _role:
      _r = _role.split('.')[1]
    else:
      _r = _role
    _clusid = conductor.get_grain_value(minion_target_names[0], '{0}.{1}.cluster.id'.format(conductor.product.lower(), _r))
  if _clusid:
    conductor.RESIZEID = int(_clusid)
 

  '''
  HOOK (common) PRE-DESTROY ORCHESTRATION (pillar://config/common.sls, config.common:hooks:pre-destroy-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target_names)
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  cc.hook_check(conductor, 'pre-destroy-orchestration', conductor.pillar_tree['config.common'], _pillars)

  '''
  HOOK (group) PRE-DESTROY ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:hooks:pre-destroy-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target_names)
  _pillars['product-group'] = conductor.product.lower()
  _pillars['resizing'] = conductor.RESIZING
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
  cc.hook_check(conductor, 'pre-destroy-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())], _pillars)

  '''
  HOOK (role) PRE-DESTROY ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:pre-destroy-orchestration)
  '''
  the_roles = []
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target_names)
  _pillars['resizing'] = conductor.RESIZING
  _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
  _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
  if not 'role' in kwargs:
    '''
    this means we are destroying based on node name or grains such as cloud or cluster id's.
    therefore, we need to create a dict map of instancename: role, because we still need to check 
    and execute any role specific pre or post destroy hook. 
    use minion_target_names above and query salt grain role for each.
    the execute the role specific pre-destroy hook if enabled
    We need to loop through all the roles found in the list of destroyable instances, and process
    role orchestration states as needed
    '''
    # GET UNIQUE ROLES FROM THE LIST OF DESTROYABLE MINON NAMES
    # DIFFERENT METHOD THAN WHEN CREATING. CREATING WE ALREADY HAVE THE ROLE LIST FROM CREATING THE CLOUD CONFIGS

    the_roles = list(set(cc.get_active_roles(conductor, minion_target_names)))
    print '-----\nthe roles\n', the_roles, '\n-----'
  else:
    the_roles.append(kwargs['role'])

  for r in the_roles:
    _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
    if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
      _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
    _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
    _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
    if not 'composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
      cc.hook_check(conductor, 'pre-destroy-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)
    else:
      _states = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['composite.role']
      if _states:
        for rs in _states:
          if not rs.split('.')[1] in the_roles:
            cc.hook_check(conductor, 'pre-destroy-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][rs.split('.')[1]], _pillars)


  # DESTROY CALL
  if 'role' in kwargs:
    logger.log('destroying all nodes matching group {0} AND role {1}'.format(kwargs['group'], kwargs['role']))

  if 'node' in kwargs:
    logger.log('destroying all instances matching group {0} AND name filter {1}'.format(kwargs['group'], kwargs['node']))

  if 'grain' in kwargs:
    the_grain = dict(kwargs['grain'])
    print the_grain
    print isinstance(the_grain, dict)
    logger.log('destroying all nodes matching group {0} AND grain {1}'.format(kwargs['group'], kwargs['grain']))


  #for m in minion_target_names:
  #  print 'destroy......', m
  #print 'exit early destroy for testing'
  #return {}

  result = cc.destroy_instances(minion_target, conductor)

  if not result:
    logger.log('destroy did not succeed, skipping post HOOKS')
    return {}

  
  '''
  IF DOWNSIZING WE NEED TO UPDATE THE cluster.members and cluster.members.ip GRAINS ON EACH REMAINING MEMBER
  '''
  
  if 'action' in kwargs and kwargs['action'] == 'downsize':
    print 'we are downsizing....'

    if conductor.DOWNSIZE_MEMBER_IP:
      print 'remove member ip =', conductor.DOWNSIZE_MEMBER_IP
      print 'remove member =', minion_target_names[0]
  
      for _m in conductor.RESIZE_CLUSTER_MEMBERS:
        print 'removing {0} from remaining member {1}'.format(minion_target_names[0], _m)
        ret = conductor._remove_grain_from_list_by_list(_m, 'cluster.members', minion_target_names[0])
        ret = conductor._remove_grain_from_list_by_list(_m, 'cluster.members.ip', conductor.DOWNSIZE_MEMBER_IP)

      # RESET THE cluster.members.info grain
      for _m in conductor.RESIZE_CLUSTER_MEMBERS:
        ret = conductor._delete_grain(_m, 'cluster.members.info')
        ret = conductor.get_grain_value(_m, 'cluster.members')
        if ret:
          _vals = {}
          for cm in ret:
            _ip = conductor.get_grain_value(cm, 'ipv4')
            _mid = conductor.get_grain_value(cm, 'cluster.member.id')

            if _ip and _ip[0] and _mid:
              _vals[cm] = {'ip': _ip[0], 'member_id': _mid}

        conductor._create_nested_grain(_m, 'cluster.members.info', _vals)


  ''' ---------------------------- POST DOWNSIZE HOOKS (THESE ARE AVAILABLE AS ROLE BASED HOOKS. I.E. NO GROUP OR ENV SCOPE -----------------------------'''
  '''
  HOOK (role) POST DOWNSIZE (CLUSTER ROLES ONLY) ORCHESTRATION (file://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:post-downsize-orchestration)
  '''
  if conductor.RESIZEID:
    for r in the_roles:
      print 'checking post downsize hooks for role:', r
      _pillars = {}
      _pillars['target-minion'] = ','.join(minion_target)
      _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
      if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
        _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
      _pillars['pillarenv'] = '{0}'.format(conductor.pillarenv)
      _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
      cc.hook_check(conductor, 'post-downsize-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)

  '''
  HOOK (common) POST-DESTROY ORCHESTRATION (pillar://config/common.sls, config.common:hooks:post-destroy-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target_names)
  cc.hook_check(conductor, 'post-destroy-orchestration', conductor.pillar_tree['config.common'], _pillars)

  '''
  HOOK (group) POST-DESTROY ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:hooks:post-destroy-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target_names)
  _pillars['product-group'] = conductor.product.lower()
  _pillars['resizing'] = conductor.RESIZING
  _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
  cc.hook_check(conductor, 'post-destroy-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())], _pillars)

  '''
  HOOK (role) POST-DESTROY ORCHESTRATION (pillar://config/PRODUCTGROUP/init.sls, productgroup.role:ROLE:hooks:post-destroy-orchestration)
  '''
  _pillars = {}
  _pillars['target-minion'] = ','.join(minion_target_names)
  _pillars['resizing'] = conductor.RESIZING
  _pillars['cluster-id'] = '{0}'.format(conductor.RESIZEID)
  for r in the_roles:
    _pillars['target-role'] = '{0}.{1}'.format(conductor.product.lower(), r)
    if 'role.base' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
      _pillars['base-role'] = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['role.base']
    if not 'composite.role' in conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]:
      cc.hook_check(conductor, 'post-destroy-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r], _pillars)
    else:
      _states = conductor.pillar_tree['{0}.{1}'.format(conductor.product.lower(), r)]['composite.role']
      if _states:
        for rs in _states:
          if not rs.split('.')[1] in the_roles:
            cc.hook_check(conductor, 'post-destroy-orchestration', conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][rs.split('.')[1]], _pillars)

  print '\nNEW CLOUD PROVISION ID {0}\n'.format(conductor.cpid)

  return {}

def replace(**kwargs):
  '''
  use case for when we need to replace existing aws instance

  required input:
    group=product-group
    instance=node-name
    pillarenv=xxx
    region=xxx
  
  other valid inputs:
    saltenv=xxxxx (this will override the default of "release"
    shell=True|False
 
  command line example:

  salt-run conduct.group replace group=productgroup instance=node-name pillarenv=dev region=us-east-1b
  '''

  if not cc.initialize():
    return {}

  if not conductor.initialize(kwargs):
    print 'initialize() failed. aws connector or pillar tree loading failed.'
    return {}

  if not util.verify_caller(this_module):
    logger.log('Cannot call submodules directly', logger.state.error)
    return{}

  if not 'instance' in kwargs:
    logger.log('instance parameter required, abort!', logger.state.error)
 
  #TODO: do aws instance lookup to check validity of instance param

  logger.log('destroying {0}'.format(instance))

  # RUN PRE-DESTROY ORCHESTRATE STATE
  # RUN PRE-DESTROY ROLE STATE

  result = cc.destroy_instances(kwargs, conductor)

  logger.log('creating {0}'.format(instance))

  result = _create(kwargs)


  return {}

def _process_role_discovery(r, minion_targets):
  '''
  builds salt command with compound target for discovering grains used to set new grains

  input:
  valid role (in the form of role not group.role)
  minions - List of minions

  return True | False
  '''

  print '\n*** get discovery for {0}.{1}'.format(conductor.product.lower(), r)

  if 'discovery' in conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r]:
    _discovery_config = OrderedDict()
    for _pitem in conductor.pillar_tree['{0}.role'.format(conductor.product.lower())][r]['discovery']:
      print '\n_pitem =', _pitem

      _filter_string = '( '
      _get_grain = None
      _desired_responses = 999
      _filters = OrderedDict()
      _local = OrderedDict()
      _set_grain = None
      _prefix = ' '
      _suffix = ' '
      _type = str
      _setval = None

      _specific_list_element = None  #if the grain to get is a list and only one element is needed, use element key (int) under discovery
      _specific_key = None           #if the grain to get is a dict a specific key only can be used.use key under discovery

      print '***DEBUGGING OVERRIDES\n _pitem', _pitem, type(_pitem)
 
      for _pk, _pv in _pitem.iteritems():
        _discovery_config[_pk] = _pv

      for _dk, _dv in _discovery_config.iteritems():
        _dv = util.convert_from_unicode(_dv)
        if 'grain' == _dk:
          _get_grain = _dv

        if 'responses' == _dk:
          _desired_responses = _dv

        if 'filter' == _dk:
          for _fk, _fv in _dv.iteritems():
            if _fv == 'CURRENT_CPID':
              _filters[_fk] = conductor.cpid
            else:
             _filters[_fk] = _fv
            if _fv == 'CURRENT_CLUSTER' and conductor.RESIZEID:
              _filters[_fk] = str(conductor.RESIZEID)
            else:
             _filters[_fk] = _fv


        if 'element' == _dk:
          _specific_list_element = _dv

        if 'key' == _dk:
          _specific_key = _dv

        if 'local' == _dk:
          for _fk, _fv in _dv.iteritems():
            if 'grain' == _fk:
              _set_grain = _fv
            if 'prefix' == _fk:
              _prefix = _fv
              if not _prefix:
                _prefix = ' '
            if 'suffix' == _fk:
              _suffix = _fv
              if not _suffix:
                _suffix = ' '
            if 'type' == _fk:
              _type = _fv


        # construct filter string
        _filter_string = '( '
        for k,v in _filters.iteritems():
          if _filter_string:
            _prev, _next, _key = _filters._OrderedDict__map[k]
            v_ = v
            if 'role' == k and not '.' in v_:
              v_ = '{0}.{1}'.format(conductor.product.lower(), v)
            if _next[2]:
              _filter_string = '{0}G@{1}:{2} and '.format(_filter_string, k, v_)
            else:
              _filter_string = '{0}G@{1}:{2} )'.format(_filter_string, k, v_)

      # construct salt command
      _cmd = 'salt -C \'* and {0}\''.format(_filter_string)

      print 'compound discover: {0}'.format(_cmd)

      ret = None

      create_nested_grain = False
      nested_value = []
      return_minion_count = 0

      grains = salt.client.LocalClient().cmd('* and {0}'.format(_filter_string), 'grains.item', [_get_grain], tgt_type='compound')

      print 'grain is:', grains

      if grains:
        if len(grains) > 1:
          create_nested_grain = True
          return_minion_count = len(grains)

        response_count = 0
        for n,m in grains.iteritems():

          if m and response_count < _desired_responses:
              
            # m is always a dict, sets it's value to the user defined grain type (str, list or dict)
            grain_value =  m[_get_grain]

            ''' --- SETTING STRING TYPE --- '''
            if _type == 'string':
              s_ = None
              if isinstance(grain_value, str):
                s_ = '{0}{1}{2}'.format(_prefix,grain_value, _suffix).strip()
              if isinstance(grain_value, list):
                if not _specific_list_element == None:
                  s_ = '{0}{1}{2}'.format(_prefix,grain_value[_specific_list_element], _suffix).strip()
                else:
                  _list_holder = []
                  for i_ in grain_value:
                    s_ = '{0}{1}{2}'.format(_prefix,i_, _suffix).strip()
                    _list_holder.append(s_)
                  s_ = ','.join(_list_holder)
              if isinstance(grain_value, dict):
                if not _specific_key == None:
                  s_ = '{0}{1}{2}'.format(_prefix, grain_value[_specific_key], _suffix).strip()
                else:
                  for dk, dv in grain_value.iteritems():
                    if s_:
                      s_ = '{0},{1}{2}:{3}{4}'.format(s_,_prefix,dk,dv, _suffix).strip()
                    else:
                      s_ = '{0}{1}:{2}{3}'.format(_prefix,dk,dv, _suffix).strip()
              if _setval:
                _setval = _setval + ',' + s_
              else:
                _setval = s_
              create_nested_grain = False
              print '**** setting string grain ******\n', _setval


            ''' ---- SETTING LIST TYPE --- '''
            if _type == 'list' and isinstance(grain_value, list):
              _setval = grain_value
            if _type == 'list' and isinstance(grain_value, str):
              _setval = grain_value.split()
            if _type == 'list' and isinstance(grain_value, dict):
              if not _specific_key == None:
                _setval = grain_value[_specific_key].split()
              else:
                _setval = [k for k,v in grain_value.iteritems()]
            if _type == 'list' and _suffix or _prefix and isinstance(_setval, list):
              _holder = []
              for i in _setval:
                _s = i
                if _suffix: 
                  _s = '{0}{1}'.format(_s, _suffix)
                if _prefix:
                  _s = '{0}{1}'.format(_prefix, _s)
                _holder.append(_s.strip())
              _setval = _holder
              print '**** setting list grain ******\n', _setval


            ''' --- SETTING DICT TYPE --- '''
            if _type == 'dict':
              d_ = {}
              if isinstance(grain_value, dict):
                if not _specific_key == None:
                  d_[_specific_key] = grain_value[_specific_key]
                else:
                  d_ = grain_value
              if isinstance(grain_value, str):
                d_ = {n, grain_value}
              if isinstance(grain_value, list):
                if not _specific_list_element == None:
                  d_[n] = grain_value[int(_specific_list_element)]
                else:
                  d_ = {(n,i) for i in grain_value}

              _newdict = {}
              for dk,dv in d_.iteritems():
                _newdict[dk] = '{0}{1}{2}'.format(_prefix,dv,_suffix).strip()
              d_ = _newdict
              _setval = dict(d_)
              print '**** setting dict grain ******\n', _setval

            response_count+=1
  
            if create_nested_grain and not return_minion_count == 0:
              if _type == 'list':
                if not _specific_list_element == None:
                  nested_value.append(_setval[int(_specific_list_element)])
                else:
                  _mergelist = nested_value + _setval
                  nested_value = list(set(_mergelist))
              else:
                nested_value.append(_setval)
              return_minion_count-=1

              if response_count >= _desired_responses:
                print 'done processing minion', n
                break
              continue
          
          else:
            print 'grain has no value'

        # we need this in the event we are building a system which will be a minion list of more than one role type
        for n in minion_targets:
          _role = None
          _r = conductor.get_grain_value(n, 'role')
          if _r and '.' in _r:
            _role = _r.split('.')[1]
          elif _r:
            _role = _r
          if _role == r:
            if create_nested_grain:
              print 'SET NEW NESTED GRAIN {0} value {1} on {2}'.format(_set_grain, nested_value, n)
              conductor._create_nested_grain(n, _set_grain, nested_value)
            else:
              print 'SET NEW GRAIN {0} value {1} on {2}'.format(_set_grain, _setval, n)
              if isinstance(_setval, list):
                for i in _setval:
                  conductor._append_grain(n, _set_grain, i)
              elif isinstance(_setval, dict):
                conductor._create_nested_grain(n, _set_grain, _setval)
              else:
                conductor.set_grain(n, _set_grain, _setval)

