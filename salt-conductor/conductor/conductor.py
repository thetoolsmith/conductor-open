'''
Conductor Class

Implements salt specific functionality 
Encapsulates Conductor executions as instances
'''
 
from __future__ import absolute_import

import salt.pillar
import salt.utils.minions
import salt.client
import salt.key
import simplejson as json
import yaml
import os, sys

#sys.path.insert(0,'../..')
from common import aws as awsc
from common.utility import Logger
import time
import random
import subprocess
from datetime import datetime, timedelta

class InitializedLocalClient(object):
  local = salt.client.LocalClient()

class Conductor(object):
  ''' 
  Conductor runtime instance
  provider MUST be specified. Others can be set after init
  '''
  def __init__(self, provider=None, product=None, environment=None, pillarenv=None, opts={}, region=None, awsconnector=None):
    from common.utility import Logger
    #from common.utility import Providers
    from groups import Providers
    from groups import Products

    if not provider:
      raise ValueError('provider MUST be specified when initializing Conductor class')

    if not provider in Providers.supported:
      raise ValueError('provider MUST be supported by Conductor')

    if not product:
      raise ValueError('product MUST be specified when initializing Conductor class')

    if not product in Products.supported:
      raise ValueError('product MUST be supported by Conductor')

    self.env = environment #state
    self.pillarenv = pillarenv #pillar/business

    self.opts = opts
    self.region = region
    self.provider = provider
    self.Products = Products
    self.productconf = None

    self.cpid = str(random.getrandbits(64)) # this is a uniquecloud provision ID used in grains as well as to set unique cloud map and logs directory 

    self.issystem = False
    self.SYSTEMID	= 0        # unique throughout the productgroup
    self.CLOUDSYSTEMID = 0   # unique throughout the salt environment
    self.SYSTEMNAME = None   # can be reused
    self.RESIZING = False
    self.RESIZE_CLOUDID = 0
    self.RESIZEID = 0     
    self.RESIZE_CLUSTER_MEMBERS = []
    self.RESIZE_CLUSTER_MEMBERS_IP = []
    self.DOWNSIZE_MEMBER_IP = None
    self.GRAINS = {}         # special grains passed in for role (not used when system is requested
    self.STATE_PILLAR = {}  # a dict of dict values

    if provider == Providers.AWS:
      self.AWS_CONNECT = awsconnector 
      self.cloud_backend = 'ec2'
    else:
      self.cloud_backend = 'vsphere'

    self.pillar_tree = {}
    self.debug = False
    self.product = product
    self.cluster_internal_roles = Products.cluster_internal_roles
    self.issandbox = False
    self.sandbox = None
    self.dte = 0 #default
    self.vpcid = None 
    self.management_vpc = None

    #print DEVOPS().__class__.__name__

    module = __import__('groups')
    class_ = getattr(module, product.upper())
    self.PGROUP = class_()
    self.productclass = self.PGROUP
    self.building_roles = []
 
    self.client = InitializedLocalClient().local
    self.logger = Logger()
    self.id_reservations = []
    self.name_reservations = []
    self.reserved_id_dir = '/srv/runners/reserved_ids'   
    self.reserved_name_dir = '/srv/runners/reserved_names'
    self.mapdir = '/srv/runners/maps/{0}'.format(self.cpid)
    self.state_run_dir = '/srv/runners/state_runs/{0}'.format(self.cpid)
    self.cloud_run_dir = '/srv/runners/cloud_runs/{0}'.format(self.cpid)
    self.nodename_suffix = ".MYDOMAIN.com"

  def initialize(self, kwargs):
    '''
    required parameters:
    pillarenv
    region
    returns True|False
    '''

    from common import utility as util
    from groups import Providers

    if 'shell' in kwargs:
      self.logger.shell = bool(kwargs['shell'])

    if 'debug' in kwargs:
      self.debug = kwargs['debug']

    if not self.pillarenv:
      if 'pillarenv' in kwargs:
        self.pillarenv = kwargs['pillarenv']
      else:
        self.logger.log('pillarenv MUST be specified', self.logger.state.error)
        return False

    if not self.env:
      if 'saltenv' in kwargs:
        self.env = kwargs['saltenv']
      else:
        # not used in CLOUD module
        self.env = 'test' #THIS IS THE DEFAULT SALT ENVIRONMENT, aka saltenv, aka the default branch in salt-state tree repository. should be  set to release in practice.
        self.logger.log('saltenv set to default \"test\"')


    if '__opts__' in kwargs:
      self.opts = kwargs['__opts__']

    if not self.region:
      if not 'region' in kwargs:
        self.logger.log("region is required", self.logger.state.error)
        return False
      else:
        self.region = kwargs['region']

    cfg = util.pillar_to_json(self.get_pillar(minion='*.{0}.*'.format(self.pillarenv), **kwargs), self.opts)

    if self.debug:
      self.logger.log(cfg)

    try:
      self.pillar_tree = json.loads(cfg)
      print 'debugging: set pillar_tree'
    except Exception as e:
      self.logger.log('Failed to convert pillar json block to dict:\n{0}\n{1}'.format(e, cfg), self.logger.state.error)
      return False

    if 'overrides' in kwargs:
      self.process_pillar_overrides(kwargs['overrides'])

    self._id = self.pillar_tree['{0}'.format(self.region[:-1])]['id']
    self._key = self.pillar_tree['{0}'.format(self.region[:-1])]['key']

    if self.provider == Providers.AWS:
      if not self.AWS_CONNECT:
        connector = awsc.create_aws_connector(aws_id=self._id, aws_key=self._key, region=self.region[:-1])
        if not connector:
          self.logger.log('Failed to get aws credentials, abort', self.logger.state.error)
          return False

        self.AWS_CONNECT = connector

    return True


  def process_pillar_overrides(self, overrides=None):
    '''
    PROCESS PILLAR OVERRIDES
    inputs:
     - conductor instance class
     - dict {"pillar:path:one": update_value, "pillar:path:two": update_value}
    return:
     - True|False

    self.pillar_tree will be updated if success
    '''

    from common import utility as util

    def _walkpillar(cfg, yamlpath, tree, value):
      ''' TODO need to make this better and not hard code yaml depth support '''
      original_value = None
      tree_updated = False
      ctr = len(yamlpath)
      if ctr == 3:
        original_value = tree[yamlpath[0]][yamlpath[1]][yamlpath[2]]
        tree[yamlpath[0]][yamlpath[1]][yamlpath[2]] = value
      if ctr == 4:
        original_value = tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]]
        tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]] = value
      if ctr == 5:
        original_value = tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]][yamlpath[4]]
        tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]][yamlpath[4]] = value
      if ctr == 6:
        original_value = tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]][yamlpath[4]][yamlpath[5]]
        tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]][yamlpath[4]][yamlpath[5]] = value
      if ctr == 7:
        original_value = tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]][yamlpath[4]][yamlpath[5]][yamlpath[6]]
        tree[yamlpath[0]][yamlpath[1]][yamlpath[2]][yamlpath[3]][yamlpath[4]][yamlpath[5]][yamlpath[6]] = value

      if original_value:
        if self.debug:
          self.logger.log('DEBUGGING PILLAR OVERRIDES')
          self.logger.log('original value type = {0}'.format(type(original_value)))
          self.logger.log('{0}'.format(original_value))
          self.logger.log('replace value type ={0}'.format(type(value)))
          self.logger.log('{0}'.format(value))
          self.logger.log('THESE NEED TO BE THE SAME TO NOT BREAK PILLAR LOGIC THROUGHOUT')
        
        tree_updated = True
        self.logger.log('changing pillar://{0}\n\t{1} --> {2}'.format(':'.join(yamlpath), original_value, value))

      return tree, tree_updated

    _mypillar = util.convert_from_unicode(self.pillar_tree)

    if self.debug:
      self.logger.log('BEGIN PILLAR\n{0}'.format(self.pillar_tree))

    isupdated = False
    if isinstance(overrides, dict):
      for k,v in overrides.iteritems():
        if self.debug:
          self.logger.log('{0} {1} {2} {3}'.format(k, type(k), v, type(v)))
        _updatedpillar, _updated = _walkpillar(k.split(':')[0], k.split(':'), _mypillar, v)
        if not isupdated and _updated:
          isupdated = True
        _mypillar = _updatedpillar

    #raise ValueError('EXIT FOR TESTING')

    if isupdated:
      self.pillar_tree = _mypillar


  def get_pillar(self, minion='*', **kwargs):
    ''' 
    private method
    Returns the compiled pillar either of a specific minion or just the global available pillars. 
    calling this function:
      get_pillar(minion='xxx') -- specific minion pillar
      get_pillar() -- global pillar for all in all
      get_pillar(minion='x', '{"pillarenv": "stage", "foo": "bar"}') -- pillar data for minion x in stage salt environment only
    '''
    id_, grains, _ = salt.utils.minions.get_minion_data(minion, self.opts)
    if grains is None:
      grains = {'fqdn': minion}

    for key in kwargs:
      grains[key] = kwargs[key]

    pillar = salt.pillar.Pillar(self.opts, grains, id_, self.pillarenv)

    compiled_pillar = pillar.compile_pillar()

    return compiled_pillar

  def get_this_master(self):
    '''
    construct the fqdn private aws dns for the salt master this is running on

    return:
      str fqdn aws saltmaster | None
    '''

    if not self.region:
      self.logger.log('region must be specified', self.logger.state.error)
      return None

    output = []

    try:
      mycmd = subprocess.Popen('uname -n', shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception:
      self.logger.log('Failed to get local machine name', self.logger.state.error)
      return None

    output, errout = mycmd.communicate()

    saltmaster = '{0}.{1}.compute.internal'.format(output.strip(), region)

    self.logger.log(saltmaster)

    return saltmaster

  # TODO test this. not sure if it's working properly
  def get_multigrain_value(self, minion=None, key=[]):
    '''  
    query loaded salt grains
    Input:
      minion - filtered salt minions
      key - grains to look for 
    Return:
      None if no minion found
      json key value if minions found 
    '''
    if not key or not minion:
      self.logger.log('grain key and minion filter are required.', self.logger.state.error)
      return None 
    if not isinstance(key, list):
      self.logger.log('grain key must be a list.', self.logger.state.error)
    if not self.client:  
      local = InitializedLocalClient().local
    else:
      local = self.client
    self.logger.log('minion={0} key={1}'.format(minion, key))
    data = local.cmd(minion, 'grains.item', key)
    self.logger.log('returned {0}'.format(data))
    if data:
      return data
    else:
      return None


  def get_grain_value(self, minion=None, key=None):
    '''
    query loaded salt grains

    Input:
    minion - glob filter salt minions
    key - grains to look for 

    Return:
    None if no minion found with key input grain
    key value if minions found 
    '''

    if not key or not minion:
      self.logger.log('grain key and minion filter are required.', self.logger.state.error)
      return None

    if not self.client:
      grains = InitializedLocalClient().local.cmd(minion, 'grains.items')
    else:
      grains = self.client.cmd(minion, 'grains.items')

    # enumerate grains for all minions and return the first one to have the matching grain
    # unless minion filter is passed in

    ret = None
    if grains:
      for n,m in grains.iteritems():
        if m and key in m and m[key]:
          ret = m[key]
        else:
          self.logger.log('grain has no value', self.logger.state.warning)

    return ret

  def set_grain(self, minion='*', key=None, value=None):
    '''
    Inputs:
      minion - salt target glob
      key - grain key
      value - grain value

    Return:  True|False
    '''
    if not key:
      self.logger.log('grain key is required.', self.logger.state.error)
      return False

    if not self.client:  
      local = InitializedLocalClient().local
    else:
      local = self.client
    try:
      grains = local.cmd(minion, 'grains.setval',['{0}'.format(key), '{0}'.format(value)])
    except Exception as e:
      self.logger.log('Failed to set grain', self.logger.state.error)
      return False

    return True

  def get_list_of_grains(self, minion=None, key=[]):
    '''  
    query loaded salt grains

    Input:
      minion - glob filtered salt minions
      key - grains to look for LIST

    Return:
      None if no minion found
      json key value if minions found 
    '''
    if not key or not minion:
      self.logger.log('grain key and minion filter are required.', self.logger.state.error)
      return None 

    if not isinstance(key, list):
      self.logger.log('grain key must be a list.', self.logger.state.error)

    if not self.client:  
      local = InitializedLocalClient().local
    else:
      local = self.client
    self.logger.log('minion={0} key={1}'.format(minion, key))
    data = local.cmd(minion, 'grains.item', ' '.join(key) )
    self.logger.log('returned {0}'.format(data))
    if data:
      return data 
    else:
      return None 

  def _delete_grain(self, minion=None, key=None, destructive=True):
    '''
    minion can be a comma delimited salt target list, or glob
    key - grain
    destructurve True|False - removes the grain entirely
    '''

    if not minion:
      self.logger.log('minion must be specified (minion target)', self.logger.state.error)
      return None

    if not self.client:
      client = salt.client.LocalClient()
    else:
      client = self.client

    grains = client.cmd(minion, 'grains.delval',['{0}'.format(key), 'destructive=' + '{0}'.format(destructive)])
    if grains:
      return True

    return True

  def _remove_grain_from_list_by_list(self, minion=None, key=None, value=None):
    '''
    minion can be a comma delimited salt target list, or glob
    key - grain
    value - list item to remove from grain
    '''

    if not minion:
      self.logger.log('minion must be specified (minion target)', self.logger.state.error)
      return None
    
    if not self.client:
      client = salt.client.LocalClient()
    else:
      client = self.client

    grains = client.cmd(minion, 'grains.remove',['{0}'.format(key), '{0}'.format(value)])
    if grains:
      return True

    return True

  def _append_grains_list(self, minion=None, key=None, value=None):
    '''
    minion is a salt list, NOT python List
    I.E. comma separated string of more than one minion
    So make sure to convert to comma delimited list before calling this function
    '''

    exec_cmd = 'salt -L \'{0}\' grains.append {1} {2} --hide-timeout'.format(minion, key, value)
    self.logger.log('running command: {0}'.format(exec_cmd))
    output = []
    try:
      mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception as e:
      self.logger.log('failed exec: {0}\n{1}'.format(exec_cmd, e), self.logger.state.error)
      return False
    output, errout = mycmd.communicate()
    if errout:
      self.logger.log('salt run may not have been successful: {0}'.format(errout), self.logger.state.warning)
      return False
    return True

  def _append_grain(self, minion=None, key=None, value=None):
    '''
    minion is a glob
    '''
    if not minion:
      self.logger.log('minion must be specified (minion target)', self.logger.state.error)
      return None 
    if not self.client:
      client = salt.client.LocalClient()
    else:
      client = self.client

    grains = client.cmd(minion, 'grains.append',['{0}'.format(key), '{0}'.format(value)])

    return

  def _create_nested_grain(self, minion=None, key=None, value=None):
    '''
    minion is a glob
    '''

    import collections

    if not minion:
      self.logger.log('minion must be specified (minion target)', self.logger.state.error)
      return None 

    def convert(data):
      if isinstance(data, basestring):
          return str(data)
      elif isinstance(data, collections.Mapping):
          return dict(map(convert, data.iteritems()))
      elif isinstance(data, collections.Iterable):
          return type(data)(map(convert, data))
      else:
          return data

    #if not self.client:
    #  client = salt.client.LocalClient()
    #else:
    #  client = self.client
    #this is not working, need to use cli command for nested dict grains
    #grains = client.cmd(minion, 'grains.setval',['{0}'.format(key), '\"{0}\"'.format(value)])

    if isinstance(minion, list):
      _holder = convert(','.join(minion))
      minion = _holder

    exec_cmd = 'salt -L \'{0}\' grains.setval {1} \"{2}\" --hide-timeout'.format(minion, key, value)
    self.logger.log('running command: {0}'.format(exec_cmd))
    output = []
    try:
      mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception as e:
      self.logger.log('failed exec: {0}\n{1}'.format(exec_cmd, e), self.logger.state.error)
      return False
    output, errout = mycmd.communicate()
    if errout:
      self.logger.log('salt run may not have been successful: {0}'.format(errout), self.logger.state.warning)
      return False
    return True

    return

  def delete_keys_from_list(self, minion=[]):
    '''  
    Delete salt minnion keys based on filter

    minion - keyname minion. I.E. *mynode.region.pillarenv*
    '''

    if not minion:
      self.logger.log('minion must be specified (minion target)', self.logger.state.error)
      return None 

    if not self.client:
      client = salt.client.LocalClient()
    else:
      client = self.client

    key_manager = salt.key.Key(client.opts)

    for m in minion:
      key_manager.delete_key(match=m)

    return 'keys removed'


  def delete_keys(self, minion=None):
    '''  
    Delete salt minnion keys based on filter

    minion - keyname minion. I.E. *mynode.region.pillarenv*
    '''

    if not minion:
      self.logger.log('minion must be specified (minion target)', self.logger.state.error)
      return None 

    if not self.client:
      client = salt.client.LocalClient()
    else:
      client = self.client

    key_manager = salt.key.Key(client.opts)

    return key_manager.delete_key(match=minion)


  def sync_modules(self, target=None):
    '''  
    target - can be list or string/glob

    UPDATE: THIS IS NOT FIXED IN 2016.11.1

    saltstack should implement a sync_modules BEFORE salt-cloud applies startup states, but it doesn't
    as of 2015.8.8.2
    '''

    if not target:
      self.logger.log('target is required list or string', self.logger.state.error)
      return False

    if isinstance(target, list):

      _convertedlist = ','.join(target)

      exec_cmd = 'salt -L \'{0}\' saltutil.sync_modules saltenv={1} --hide-timeout'.format(_convertedlist, self.env)

    else:

      exec_cmd = 'salt \'{0}\' saltutil.sync_modules saltenv={1} --hide-timeout'.format(target, self.env)

    output = [] 
    try: 
      mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )

    except Exception as e:
      self.logger.log('Failed to run sync_modules', self.logger.state.error)
      return False

    output, errout = mycmd.communicate()

    if errout:
      self.logger.log('salt sync_modules returned error: {0}'.format(errout), self.logger.state.error)
      return False

    time.sleep(10)

    self.logger.log('sync_modules success!')

    return True 

  def run_startup_states(self, target=None, run_state=None):
    '''
    target - valid target. list, grain, glob are supported. Compound NOT supported yet
    run_state - List or comma delim string of valid salt states to run
    '''
    if not run_state or not target:
      self.logger.log('target and run_state are required', self.logger.state.error)
      return False

    time.sleep(10)

    _states = [] 

    if isinstance(run_state, list):
      _states = run_state
    else:
      _states.append(run_state)

    failed = 0

    for _state in _states:

      has_state_pillar = {}

      print 'debug: running state\n', _state

      # EVALUATE STATE_PILLAR 
      for spillar, pillarval in self.STATE_PILLAR.iteritems():
        if spillar == _state:
          has_state_pillar = pillarval

      if ',' in target:
        # TARGET BASED ON LIST
        exec_cmd = 'salt -L \'{0}\' state.sls {1} pillarenv={3} saltenv={2} --hide-timeout'.format(target, _state, self.env, self.pillarenv)
      elif ':' in target:
        # TARGET BASED ON GRAIN
        exec_cmd = 'salt -G \'{0}\' state.sls {1} pillarenv={3} saltenv={2} --hide-timeout'.format(target, _state, self.env, self.pillarenv)
      else:
        # TARGET BASED ON MINION OR GLOB
        exec_cmd = 'salt \'{0}\' state.sls {1} pillarenv={3} saltenv={2} --hide-timeout'.format(target, _state, self.env, self.pillarenv)

      if has_state_pillar:
        exec_cmd = '{0} {1}'.format(exec_cmd, 'pillar=\'{0}\''.format(has_state_pillar))

      if _state == 'new-instance':
        print 'debug: passing STATE_PILLAR to new-instance state'
        has_state_pillar = self.STATE_PILLAR
        _d = {}
        _d['statepillars'] = self.STATE_PILLAR
        exec_cmd = '{0} {1}'.format(exec_cmd, 'pillar=\'{0}\''.format(_d))

      # NOTE: COMPOUND MATCHING IS NOT SUPPORTED. CREATE ANOTHER METHOD IF NEEDED!!

      print 'debug: the command\n', exec_cmd

      output = [] 
 
      try: 
        mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
      except Exception as e:
        self.logger.log('Failed to run startup state {0}\n{1}'.format(_state, e), self.logger.state.error)
        failed+=1
        continue

      output, errout = mycmd.communicate()

      if errout:
        self.logger.log('salt command: {0}'.format(exec_cmd))
        self.logger.log('returned error: {0}'.format(errout), self.logger.state.error)
     
      if self.debug:
        print 'STATE RUN OUTPUT\n', output
 
      state_output = 'state_run-{2}_{0}_{1}.out'.format(os.path.basename(__file__)[:-3], \
                                                         str(random.getrandbits(8)), self.product )

      self.logger.log('STATE RUN\n{0}'.format(state_output))

      if self.debug:
        print 'debug: state run output START\n', output, '\nFINISH\n'
 
      with open('{0}/{1}'.format(self.state_run_dir, state_output), 'w') as f:
        f.write('{0}\n'.format(output))

    if failed:
      self.logger.log('{0} states failed to run'.format(failed), self.logger.state.error)
      return False

    return True

  def get_subnet_id(self, subnet=None):
    ''' 
    get specified subnet from pillar
    input:
      subnet - type of subnet. example options private | public | management

    TODO: could expand the available type options as new products use conductor and pillar data is added
    ''' 

    if not subnet:
      self.logger.log('subnet is required', self.logger.state.error)
      return None

    subnet_id = None 
    try: 
      subnet_id = self.pillar_tree['{0}'.format(self.region[:-1])]['subnet'][subnet]['availability']['zone_{0}'.format(self.region[-1:])]
    except:
      self.logger.log('Failed to locate pillar data for {0} subnet in region {1} zone {2}'.format(subnet, self.region[:-1],  self.region[-1:]), \
                      self.logger.state.error)    
      return None

    if not subnet_id:
      self.logger.log('Failed to determine {0} subnet for region {1} zone {2}'.format(subnet, self.region[:-1], self.region[-1:]), \
                      self.logger.state.error)
      return None

    return subnet_id

  def create_profile_provider_conf(self, config):
    '''
    generate the new profile and provider conf
    inputs: 
      kwargs - dict of required key/value pairs 
               required: [configname, subnet, ami]
               optional: [default_start, security_group]

               configname - product specific name for conf files (i.e. PRODUCT_II_NAME-create | PRODUCT_NAME-destroy)
               subnet - subnet type example options private | public | management
               ami - ami-image to use
               default_start - startup state
               security_group - security group id
    '''   
    required_args = ['configname', 'subnet', 'ami']
    for ra in required_args:
      if not ra in config:
        self.logger.log('{0} must be specified'.format(ra), self.logger.state.error)
        return False

    private_key = self.pillar_tree['{0}'.format(self.region[:-1])]['private_key']
    keyname = self.pillar_tree['{0}'.format(self.region[:-1])]['keyname']
    #required_subnet_id = self.get_subnet_id(config['subnet'])
    required_subnet_id = config['subnet']
    if not required_subnet_id:
      return False

  
    provider_name = '{0}_{1}'.format(self.product.lower(), self.cpid)
    
    newprovider = '/etc/salt/cloud.providers.d/{0}_{1}.conf'.format(self.product.lower(), self.cpid)

    self.logger.log('new provider {0}'.format(newprovider))

    f = open(newprovider, "w")
    f.write('{0}:\n'.format(provider_name))
    f.write('  rename_on_destroy: False\n')

    '''
    TIP: if persist-volumes is set at the instance config level in cloud map, that will override this in provider
    for common, if persist-volumes does NOT exist in config.common pillar, we set to destroy volumes as default
    if persist-volumes is set in config.common pillar, we use that value. Must be True | False
    TIP: we do NOT set persist-volumes in the profile.conf, only provider.conf and optional override in cloud map
    '''

    if 'persist-volumes' in self.pillar_tree['config.common']:
      if str(self.pillar_tree['config.common']['persist-volumes']).lower() == "true":
        f.write('  del_root_vol_on_destroy: False\n')
        f.write('  del_all_vols_on_destroy: False\n')
      else:
        f.write('  del_root_vol_on_destroy: True\n')
        f.write('  del_all_vols_on_destroy: True\n')
    else:
      f.write('  del_root_vol_on_destroy: True\n')
      f.write('  del_all_vols_on_destroy: True\n')

      f.write('  rename_on_destroy: False\n')

    f.write('  minion:\n')

    '''
    TODO: VERIFY MULTI MASTER CONFIG IF NEEDED
    if 'salt_master' in self.pillar_tree['{0}'.format(self.region[:-1])]:
      saltmasters = self.pillar_tree['{0}'.format(self.region[:-1])]['salt_master']
      if isinstance(saltmasters, list):
        self.logger.log('Setting saltmaster MULTI master {0}'.format(saltmasters))
        f.write('    master:\n')
        for sm in saltmasters:
          f.write('      - {0}\n'.format(sm))
        f.write('    master_type: failover\n')
      else:
        self.logger.log('Setting saltmaster SINGLE master {0}'.format(saltmasters))
        f.write('    master: {0}\n'.format(self.pillar_tree['{0}'.format(self.region[:-1])]['salt_master']))
    else:
      self.logger.log('Setting saltmaster local machine')
      f.write('    master: {0}\n'.format(self.get_this_master()))
    '''

    # SET DEFAULT SIZE TO AVOID BUG IN SALT 2015.8 WHICH BROKE OVERRIDE
    f.write('  size: t2.small\n')
    f.write('  ssh_interface: private_ips\n') #TODO need to make this optional
    f.write('  id: {0}\n'.format(self._id))
    f.write('  key: {0}\n'.format(self._key))  #TODO need to test encryption 
    f.write('  private_key: {0}\n'.format(private_key))
    f.write('  keyname: {0}\n'.format(keyname))
    f.write('  location: {0}\n'.format(self.region[:-1]))
    f.write('  driver: {0}\n'.format(self.cloud_backend))
    f.close()

    # CREATE PROFILE (PROVIDER FILE IS USED ON DESTROYINSTANCE EVENT, SO INCLUDE ZONE IN NAME)
    minion_version = self.pillar_tree['global']['salt-minion']['version']
    sshuser = self.pillar_tree['{0}'.format(self.region[:-1])]['ssh_username']

    self.logger.log('using image {0}'.format(config['ami']))

    profile_name = '{0}_{1}'.format(self.product.lower(), self.cpid)

    newprofile = '/etc/salt/cloud.profiles.d/{0}_{1}.conf'.format(self.product.lower(), self.cpid) 

    f = open(newprofile, "w")

    self.logger.log('new profile {0}'.format(newprofile))

    f.write('{0}:\n'.format(profile_name))
    f.write('  provider: {0}\n'.format(provider_name))

    if minion_version:
      f.write('  script_args: \'-P git v{0}\'\n'.format(minion_version))
    f.write('  minion:\n')
    f.write('    environment: {0}\n'.format(self.env))
    f.write('    pillarenv: {0}\n'.format(self.pillarenv))

    if self.debug:
      print 'dumping passed in config to create_profile_provider_conf\n'
      for x,y in config.iteritems():
        print x, '----', y
      print '\n'

    if 'default_start' in config:
      f.write('    startup_states: sls\n')
      f.write('    sls_list:\n')
      f.write('      - {0}\n'.format(config['default_start'])) #this can be overwritten in map per role

    f.write('  availability_zone: {0}\n'.format(self.region))
    f.write('  image: {0}\n'.format(config['ami']))
    f.write('  ssh_username: {0}\n'.format(sshuser))
    f.write('  network_interfaces:\n')
    f.write('    - DeviceIndex: 0\n')
    f.write('      SubnetId: {0}\n'.format(required_subnet_id))

    if 'security_group' in config:
      f.write('      SecurityGroupId:\n')
      f.write('        - {0}\n'.format(config['security_group']))
    f.write('      allocate_new_eip: False\n')

    # TODO: until dns is configured, we need to create vm with public ip otherwise salt bootstrap fails
    f.write('      AssociatePublicIpAddress: True\n')

    f.close()

    return True

  def create_new_meta(self, clouddata):
    '''  
    parse cloud data to create a meta data node list, add to class conf
    inputs:
      clouddata - formatted return from salt-cloud
      product conf class
    return:
      True|false, updated product conf class node_meta list
    ''' 
    if not clouddata or not isinstance(clouddata, dict):
      self.logger.log('Invalid cloud data dict passed.', self.logger.state.error)
      return False, []

    try: 
      for node, data in clouddata.items():

        result, node_data = awsc.create_new_cloud_meta(node, data)

        # TODO need to check here to see if the entry, node_data which will be a dict have and empty dict as value
        if result and node_data:
          if isinstance(node_data, dict):
            for k,v in node_data.iteritems():
             if isinstance(v, dict):
               if not v:
                 self.logger.log('Failed to salt bootstrap new vm {0}'.format(k), self.logger.state.error)
                 return False, []
               else: 
                 self.logger.log('\nadding to Conductor class conf: {0}'.format(node_data))

          self.productconf.node_meta.append(node_data)

    except:
      return False, []

    return True

  def build_cloud(self, configname=None, target=None, expected_nodes=[], cloudmap=None):
    '''  
    prepare the cloud map file and build

    inputs:
      configname - unique name to be used for profile and provider conf
      target - minions filter
      cloudmap - configured map
      expected_nodes[] - list of vm to have been created, used for verification

    return:
      True - success
      False - failed
    '''
    from common import utility as util

    if not configname or not target or not cloudmap:
      self.logger.log('configname, target and cloudmap are required parameters')
      return False

    # CALL SALT-CLOUD HERE
    retcode, output = awsc.call_saltcloud(cloudmap)
    if not retcode:
      self.logger.log('Failed salt-cloud, abort!', self.logger.state.error)
      return False

    cloudoutput = 'cloud_run-{0}_{2}_{1}.out'.format(os.path.basename(__file__)[:-3],str(random.getrandbits(8)), configname)
    with open('{0}/{1}'.format(self.cloud_run_dir, cloudoutput), 'w') as f:
      f.write('{0}\n'.format(output))

    # EVAULATE RETURNED OUTPUT 
    try: 
      saltcloud_data = dict(json.loads(output))
      # TODO could improve this error handling by looking into the json deeper              
      if 'failed. Exit code:' in output:
        raise ValueError('salt-cloud returned error when provisioning')

    except Exception as e:
      self.logger.log('Failed to convert salt-cloud data to dict, might be invalid json\n{0}\n'.format(e), self.logger.state.error)
      self.logger.log('removing minion keys...')
      self.logger.log(output)

      if isinstance(target, list):
        results = self.delete_keys_from_list(minion=target)
      else:
        results = self.delete_keys(minion=target)
      self.logger.log(results)
      return False

    if self.debug:
      print 'salt cloud json\n', util.print_pretty_dict(saltcloud_data)


    # VERIFY NEW EXPECTED NODES WERE ACTUALLY CREATED
    failed_nodes = [] 
    try: 
      for node, data in saltcloud_data.items():
        #check for empty dict
        if not data:
          self.logger.log('{0}-----{1}'.format(node, data))
          self.logger.log('AWS Failed to create {0}'.format(node), self.logger.state.error)
          failed_nodes.append(node)
          continue

        node_built = False
        for n in expected_nodes:
          if n == node:
            node_built = True 
        if not node_built:
          self.logger.log('Failed to create {0}'.format(n), self.logger.state.error)
          failed_nodes.append(node)
    except:
      self.logger.log('Failed to iterate saltcloud_data', self.logger.state.error)
      return False

    if failed_nodes:
      self.logger.log('\nSome vms were not created!, abort.\n{0}\n'.format(failed_nodes), self.logger.state.error)
      self.logger.log('\nHINT: search log for \n\'500 Server Error: Internal Server Error\'\nor\n\'400 Client Error: Bad Request\'\n to learn more\n')

      return False

    result = self.create_new_meta(saltcloud_data)
    if not result:
      self.logger.log('There was a problem collecting cloud metadata for new nodes.', self.logger.state.warning)

    # strips unicode format
    def convert(data):
      if isinstance(data, basestring):
          return str(data)
      elif isinstance(data, collections.Mapping):
          return dict(map(convert, data.iteritems()))
      elif isinstance(data, collections.Iterable):
          return type(data)(map(convert, data))
      else:
          return data

    # CHANGE HOSTNAME ON NEW NODE
    output = [] 
    try:
      if isinstance(target, list):
        _target = ','.join(target)
        cmd = 'salt -L \'{0}\' cmd.run template=jinja \"salt-call network.mod_hostname {1}{{grains.id}}{2}\" saltenv={3} --hide-timeout'.format(_target, '{', '}', self.env)
      else: 
        if ',' in target:
          # TARGET BASED ON LIST
          cmd = 'salt -L \'{0}\' cmd.run template=jinja \"salt-call network.mod_hostname {1}{{grains.id}}{2}\" saltenv={3} --hide-timeout'.format(target, '{', '}', self.env)
        elif ':' in target:
          # TARGET BASED ON GRAIN
          cmd = 'salt -G \'{0}\' state.sls {1} pillarenv={3} saltenv={2} --hide-timeout'.format(target, _state, self.env, self.pillarenv)
        else:
          # TARGET BASED ON MINION OR GLOB
          cmd = 'salt \'{0}\' state.sls {1} pillarenv={3} saltenv={2} --hide-timeout'.format(target, _state, self.env, self.pillarenv)


      #original below 
      #cmd = 'salt \'{0}\' cmd.run template=jinja \"salt-call network.mod_hostname {1}{{grains.id}}{2}\" saltenv={3}'.format(target, \
      #                                                                                                                      '{', '}', self.env)
      self.logger.log('CHANGING HOSTNAME on minions:\n{0}'.format(cmd))
      mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception as e:
      self.logger.log('Failed to change hostnames on minions\n{0}'.format(e), self.logger.state.error)

    output, errout = mycmd.communicate()

    self.logger.log('hostname change return:\n{0}'.format(output))

    '''
    CUSTOM CODE TO GET SECURE DNS CONFIG FROM PILLAR AND PUBLISH TO EXTERNAL DNS REMOVED
    FOR THIS IMPLEMENTATION
    '''

    return True

