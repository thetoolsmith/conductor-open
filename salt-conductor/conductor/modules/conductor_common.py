'''
conductor_common.py
common functions shared by all Conductor submodules
'''
import os, sys
import random
import re
import collections
from common import aws as awsc
from modules import discovery as discover
import time
import subprocess

def get_elastic_ips(c, logger, aws):
  '''  
  Pass Conductor instance, logger instance, awsc instance from calling module
  This function will get a list of elastic ips for a given aws region
  Return: list of dict values [{public_ip:allocation-id}]
  '''
  results, eips = aws.get_aws_elasticips(awsconnector=c.AWS_CONNECT)
  if eips and isinstance(eips, list):
    for ip in eips:
      if isinstance(ip, dict):
        for k,v in ip.iteritems():
          logger.log('ip={0} id={1}'.format(k,v))
    return eips 
  return []  

def initialize(c):
  ''' 
  Pass instance of Conductor
  some inititialization of module instance
  '''

  try:
    if not os.path.isdir(c.reserved_name_dir):
      os.mkdir(c.reserved_name_dir, 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create {0}\n{1}'.format(c.reserved_name_dir, e))
  try:
    if not os.path.isdir(c.reserved_id_dir):
      os.mkdir(c.reserved_id_dir, 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create {0}\n{1}'.format(c.reserved_id_dir, e))

  try:
    if not os.path.isdir('/srv/runners/maps'):
      os.mkdir('/srv/runners/maps', 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create /srv/runners/maps\n{0}'.format(e))

  try:
    if not os.path.isdir(c.mapdir):
      os.mkdir(c.mapdir, 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create {0}\n{1}'.format(c.mapdir, e))

  try:
    if not os.path.isdir(c.state_run_dir):
      os.mkdir(c.state_run_dir, 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create {0}'.format(c.state_run_dir))

  try:
    if not os.path.isdir(c.cloud_run_dir):
      os.mkdir(c.cloud_run_dir, 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create {0}'.format(c.cloud_run_dir))

  return True


def run_state(c, logger, target, state_to_run):
  ''' 
  Pass instance of Conductor, logger, target, salt state
  supports glob only at this point
  '''
  logger.log('Running {1} on {0}...'.format(target, state_to_run))

  exec_cmd = 'salt \'*{0}*\' state.sls {1} pillarenv={3} saltenv={2}'.format(target, state_to_run_, c.env, c.pillarenv)

  logger.log('running {0}'.format(exec_cmd))

  output = []
  try:
    mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    logger.log('shutdown state run failed', l.state.error)
    return False

  output, errout = mycmd.communicate()

  if output:
    outfile = 'state_run-{0}_{1}.out'.format(os.path.basename(__file__)[:-3],str(random.getrandbits(16)))

    if c.debug:
      print 'STATE RUN OUTPUT:\n', output

    with open('{0}/{1}'.format(c.state_run_dir, outfile), 'w') as f:
      f.write('{0}\n'.format(output))
    return True
  else:
    return False


def new_exec_orchestration_state(c, dynamic_pillar, state_to_run):
  '''
  c - conductor class instance
  dynamic_pillar - dict of pillar keys and values
  state_to_run - string or List of salt orchestrate states to run

  execute a salt orchestration state (executes on master)
  return False on fail, True success
  '''

  if not dynamic_pillar or not state_to_run:
    return False
  if not isinstance(dynamic_pillar, dict):
    return False
  if not 'target-minion' in dynamic_pillar:
    return False


  states = []
  if not isinstance(state_to_run, list):
    states = state_to_run.split()
  else:
    states = state_to_run

  target_minion = dynamic_pillar['target-minion']

  if ',' in dynamic_pillar['target-minion']:
    _holder = dynamic_pillar['target-minion'].replace(',', ' or ')
    target_minion = _holder.encode('utf8')

  _pillars = None
  for k,v in dynamic_pillar.iteritems():
    if not _pillars == None:
      _pillars = '{0}{1}{2}{3}{4}{5}{6}'.format(_pillars, ', \"', k, '\": ', '\"', v, '\"')
    else:
      _pillars = '{0}{1}{2}{3}{4}{5}'.format('\"', k, '\": ', '\"', v, '\"')  

  _pillarcmd = []
  _pillarcmd.append("pillar=\'{")
  _pillarcmd.append(_pillars)
  _pillarcmd.append("}\'")

  print "*** DEBUG PILLARCMD", ''.join(_pillarcmd)

  for s in states:
    print 'target minion: {0}'.format(target_minion)
    exec_cmd = 'salt-run state.orchestrate {0} pillarenv={1} saltenv={2} {3}'.format(s.encode('utf8'), c.pillarenv, c.env, ''.join(_pillarcmd))

    print 'running {0}'.format(exec_cmd)
    output = []
    try:
      mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception as e:
      print 'failed to run orchestration state {0}'.format(s)
      return False
    output, errout = mycmd.communicate()
    if output:
      outfile = 'orch_state_run-{0}_{1}.out'.format(os.path.basename(__file__)[:-3], str(random.getrandbits(16)))
      if c.debug:
        print 'STATE RUN OUTPUT:\n', output
      with open('{0}/{1}'.format(c.state_run_dir, outfile), 'w') as f:
        f.write('{0}\n'.format(output))

  return True


def convert(data):
  if isinstance(data, basestring):
      return str(data)
  elif isinstance(data, collections.Mapping):
      return dict(map(convert, data.iteritems()))
  elif isinstance(data, collections.Iterable):
      return type(data)(map(convert, data))
  else:
      return data

def create_prebuild_object(c, the_role, num, **kwargs):

  '''
  Pass instance of Conductor
  This gets called for each role that is being built. A role may be a cluster which is multiple instance.
  return as dict.
  The dict will be one only, unless it's a cluster. then its 1+x where x is the cluster member internal role.
  '''

  components_to_build = []
  component = None
  component = c.PGROUP.Prebuild().component   #instanciate new DICT component from class instance
  roleid = '{0}.{1}'.format(c.product.lower(), the_role)
  iscomposite = ('composite.role' in c.pillar_tree[roleid])

  # NOTE: ROLEID IS THE TEAM UNIQUE ROLE WHEN USING SHARED ROLES. I.E. productgroup1.cassandra vs. productgroup2.cassandra 
  # make sure the role config exists in productgroup.role, or has composite.role grain at pillar root
  if component and ((the_role in c.pillar_tree['{0}.role'.format(c.product.lower())]) or iscomposite):
    if not iscomposite:
      # THE INITIAL SEC GROUP AND SUBNET CAN BE EITHER PUBLIC, PRIVATE 
      if 'security-group' in c.pillar_tree['{0}.role'.format(c.product.lower())][the_role]:
        component['security-group'] = c.pillar_tree['{0}.role'.format(c.product.lower())][the_role]['security-group']
      if 'subnet' in c.pillar_tree['{0}.role'.format(c.product.lower())][the_role]:
        component['subnet'] = c.pillar_tree['{0}.role'.format(c.product.lower())][the_role]['subnet']

    component['roleid'] = roleid #this is roleid instead of the_role
    cfg = c.pillar_tree[roleid] 

    def convert(data):
      if isinstance(data, basestring):
          return str(data)
      elif isinstance(data, collections.Mapping):
          return dict(map(convert, data.iteritems()))
      elif isinstance(data, collections.Iterable):
          return type(data)(map(convert, data))
      else:
          return data

    if 'nodes' in cfg:
      component['nodes'] = cfg['nodes']

    # SET VALUES THAT DON'T CHANGE IF ITS A CLUSTER ROLE OR NOT
    component['role'] = cfg['role']
    if 'role.base' in cfg:
      component['baserole'] = cfg['role.base']

    '''
    CUSTOM GRAINS
    '''
    _list_of_grains = []
    _d = {}
    if 'additional-grains' in cfg:
      # CLEANUP THE FORMAT OF DICT. THIS IS NEEDED BECAUSE SALT SCOOPS THE PILLAR TREE YAML AND 
      # THE DATA IS FORMATTED IN UNICODE SO WE NEED TO RE-FORMAT WITH LITERAL STRINGS FOR ALL OBJECTS
      # ALSO NOTE, THIS KEY DOES NOT APPEAR IN THE DEFAULT compoonent object OF Conductor class
      for k,v in cfg['additional-grains'].iteritems():
        _v = convert(v)
        _d[str(k)] = _v


    '''
    HOOK GRAINS - need to create a grain for each hook (group and role) that is enabled. pre-provision hook happens before instance, so no grain used
    '''
    def _create_hook_grains(_hook_pillar, hooktype):
      if 'hooks' in _hook_pillar:
        _hooks = ['pre-provision-orchestration', 'pre-startup-orchestration', 'post-startup-orchestration']
        for _hook in _hooks:
          if (_hook in _hook_pillar['hooks']) and ('enable' in _hook_pillar['hooks'][_hook]) and (_hook_pillar['hooks'][_hook]['enable'] == True) and ('state' in _hook_pillar['hooks'][_hook]):
            _d['{1}.{0}'.format(_hook.replace('-','.'), hooktype)] = convert(_hook_pillar['hooks'][_hook]['state'])

    _create_hook_grains(c.pillar_tree['config.common'], 'common')
    _create_hook_grains(c.pillar_tree['{0}.role'.format(c.product.lower())], 'group')
    # create role scoped hook grains only if it's not a composite role
    if not iscomposite:
      _create_hook_grains(c.pillar_tree['{0}.role'.format(c.product.lower())][the_role], 'role')

    if 'cluster' in cfg and cfg['cluster'] == True:
      # get next available GROUP role clusterid grain
      implemented_role = component['role']
      if '.' in component['role']:
        implemented_role = component['role'].split('.')[1]
      _id_available = False
      theid = 0

      if c.RESIZEID:
        theid = c.RESIZEID
      else:
        while not _id_available:
          # TODO may need to add saltenv grains to all and use this as well so salt master know what environment to target, salt doesn't create that grain by default
          _id_available, theid = next_clusterid(c, True, implemented_role, minion='G@{0}.cluster.id:* and G@role:{0}'.format(component['role']))

      if _id_available or c.RESIZEID:
        _d['{0}.{1}.cluster.id'.format(c.product.lower(), implemented_role)] = theid

      _id_available = False
      theid = 0

      if c.RESIZE_CLOUDID:
        theid = c.RESIZE_CLOUDID
      else:
        # get next available CLOUD (env scoped) role clusterid grain 
        while not _id_available:
          _id_available, theid = next_clusterid(c, False, implemented_role, minion='G@cloud.{0}.cluster.id:* and G@role:{1}'.format(implemented_role, component['role']))

      if _id_available or c.RESIZE_CLOUDID:
        _d['cloud.{0}.cluster.id'.format(implemented_role)] = theid
  

    ''' 
    COMMAND LINE GRAINS
    '''
    if c.GRAINS:
      for k,v in c.GRAINS.iteritems():
        _v = convert(v)
        _d[str(k)] = _v

    if (len(_d) > 0):
      _list_of_grains.append(_d)
      component['additionalgrains'] = _list_of_grains

    '''
    CUSTOM TAGS
    '''
    if 'tags' in cfg:
      _l = []
      _d = {}
      for k,v in cfg['tags'].iteritems():
        _v = convert(v)
        _d[str(k)] = _v
      _l.append(_d)
      component['tags'] = _l

    # IF NUM IS -1, the command line was role=all and we use the node count for each role from pillar template
    # THIS GETS OVERWROTE IF CLUSTER (BELOW)
    if not (num == -1):
      component['nodes'] = int(num)

    if 'force-delay-state' in cfg:
      component['force_delay_state'] = cfg['force-delay-state']

    def _create_component(internalrole, c, seed_component, cfgvals):
      _component = seed_component
      _component['pattern'] = cfgvals['basename'] #required
      _component['size'] = cfgvals['size'] #required
      if internalrole: #IS A CLUSTER MEMBER
        if 'nodes' in cfgvals:
          _component['nodes'] = cfgvals['nodes']
      else:       
        if not 'nodes' in _component:
          _component['nodes'] = "1"

      if c.RESIZEID > 0:
        _component['nodes'] = str(kwargs['members'])

      if 'composite.role' in cfgvals:
        newlist = []
        for x in list(cfgvals['composite.role']):
          newlist.append(convert(x))
        _component['compositerole'] = list(newlist)

      if 'startup-override' in cfgvals:
        _component['startupoverride'] = list(cfgvals['startup-override'])

      if 'ami-override' in cfgvals:
        _component['ami_override'] = cfgvals['ami-override'][c.region[:-1]]

      if 'persist-volumes' in cfgvals:
        _component['persist_volumes'] = cfgvals['persist-volumes']

      if 'volume-info' in cfgvals:
        _component['volume_info'] = cfgvals['volume-info']

      if 'ebs-optimized' in cfgvals:
        _component['ebs_optimize'] = cfgvals['ebs-optimized']

      ''' quick way is to keep our pillar config consistent with salt cloud required syntax (i.e. underscores instead of dash)
          however, if we want to put controls and check user pillar data for accuracy, we still need to check each key/value pair.
          not doing that here at this point. we are just taking pillar config and assuming it's the accurate salt-cloud config representation
      '''
      if 'spot_config' in cfgvals and 'spot_price' in cfgvals['spot_config'] and cfgvals['spot_config']['spot_price']:
        _component['spot_config'] = cfgvals['spot_config']


      ''' block device overriding '''
      _block_pillar = None
      if 'block-volume' in c.pillar_tree[_component['roleid']]:
        _block_pillar = c.pillar_tree[_component['roleid']]['block-volume']
      elif 'block-volume' in c.pillar_tree['config.common']:
        _block_pillar = c.pillar_tree['config.common']['block-volume']
      if _block_pillar:
        if not isinstance(_block_pillar, list):
          print 'block-volume in provisioning configuration MUST be a List yaml type' 
        else:
          _component['block_volume_info'] = _block_pillar

      ''' root volume tagging '''
      if 'root-volume-tags' in c.pillar_tree[_component['roleid']] and isinstance(c.pillar_tree[_component['roleid']]['root-volume-tags'], dict):
        _component['root_volume_tags'] = c.pillar_tree[_component['roleid']]['root-volume-tags']

      if internalrole:
        _component['internalrole'] = internalrole

      components_to_build.append(_component)
 
      return _component

 
    if 'cluster' in cfg and cfg['cluster'] == True:

      component['iscluster'] = cfg['cluster'] #this is only true|false. internal_roles (maybe cluster-config now)is the actual config needed for the cloud map
      if component['iscluster'] == True:
        if 'members' in kwargs: # NOTE: members should always be in kwargs when action is upsize

          print '***** MEMBERS ON CMDLINE *****\n', kwargs['members']

          _prectr = 1 #always one primary, unless resizing
          if c.RESIZEID > 0:
            _prectr = 0

           
          #-------------------- PROCESS ROLES USING UPSTREAM ROLE CONFIG FIRST -------------------

          using_upstream_config = []
          for k,v in cfg['cluster-config'].iteritems():
            if 'upstream-config' in v and v['upstream-config'] == True:
              using_upstream_config.append(k)

          # GET THE PRIMARY FIRST
          if not c.RESIZEID > 0:
            for k in using_upstream_config:
              v = cfg['cluster-config'][k]
              _seed = {}
              if k == 'primary':
                for key,val in component.iteritems():
                  _seed[key] = val
                cfg['nodes'] = 1
                cfg['basename'] = v['basename']

              else:
                continue
              _create_component(str(k),c, _seed, cfg)
          
          # THEN SECONDARY (skip other)
          if int(kwargs['members']) > 1 or c.RESIZEID > 0:
            for k in using_upstream_config:
              v = cfg['cluster-config'][k]
              _seed = {}
              if not k == 'primary':
                # this is a bug using upstream-config with systems only when uncommented????? not sure why it was there
                # commented on 09-13-2018 
                #if c.SYSTEMNAME:
                #  continue           

                if not k in c.cluster_internal_roles:
                  continue
                #if not k == 'secondary':     
                #  continue

                _seed = {}
                if _prectr >= int(kwargs['members']):
                  break
                else:
                  for key,val in component.iteritems():
                    _seed[key] = val
                  if c.RESIZEID > 0:
                    cfg['nodes'] = int(kwargs['members']) #when resizing, don't use primary. always add secondaries
                  elif 'nodes' in v and (int(v['nodes']) <= (int(kwargs['members']) - 1)):
                    cfg['nodes'] = (int(kwargs['members']) - 1)
                  else:
                    pass
                  if _prectr >= int(kwargs['members']):
                    break
                  cfg['basename'] = v['basename']

                  _create_component(str(k),c, _seed, cfg)
                  _prectr += cfg['nodes']
          # ---------------------------------------------------------------------------------------  

          for k in using_upstream_config:
            print 'removing {0} from cluster-config'.format(k)

            del cfg['cluster-config'][k]

          #--------------------------------PROCESS REMAINING INTERNAL ROLES NOT USING UPSTREAM CONFIG ----------------------------
          if c.RESIZEID == 0:  #only process primary of not resizing
            for k,v in cfg['cluster-config'].iteritems():
              _seed = {}
              if k == 'primary':
                for key,val in component.iteritems():
                  _seed[key] = val
                v['nodes'] = 1
              else:
                continue

              _create_component(str(k),c, _seed, v)

          if int(kwargs['members']) > 1 or c.RESIZEID > 0: 
            for k,v in cfg['cluster-config'].iteritems():
              _seed = {}
              if _prectr >= int(kwargs['members']):
                break
              if k == 'primary':
                continue

              if not k in c.cluster_internal_roles:
                continue
              #if not k == 'secondary':     
              #  continue
              else:
                for key,val in component.iteritems():
                  _seed[key] = val
                if c.RESIZEID > 0:
                  v['nodes'] = int(kwargs['members'])
                elif 'nodes' in v and (v['nodes'] == (int(kwargs['members']) - 1)):
                  pass
                else:
                  v['nodes'] = (int(kwargs['members']) - 1)

                if _prectr >= int(kwargs['members']):
                  break

                _create_component(str(k),c, _seed, v)

                _prectr += v['nodes']
        else:

          # should never be here when upsizing

          for k,v in cfg['cluster-config'].iteritems():
            _seed = {}
            for key,val in component.iteritems():
              _seed[key] = val

            if 'upstream-config' in v and v['upstream-config'] == True:
              v = cfg['cluster-config'][k]
              cfg['nodes'] = v['nodes']
              cfg['basename'] = v['basename']
              _create_component(str(k),c, _seed, cfg)
            else:
              _create_component(str(k),c, _seed, v)
             
    else: 
      _create_component(None, c, component, cfg) 


  #print "RETURNING COMPONENTS TO BUILD\n"
  #for c in components_to_build:
  #  print c

  return components_to_build


def create_cloud_config(c, components, existing_nodes=[]):
  '''  
  Pass instance of Conductor object
  construct node names based on template patterns.
  this function gets called for one component/role at a time (could be a cluster in which case we use internal role)
  populates instance dict object Conductor.PGROUP.new_cloud_config
  return True|False
  '''


  def bump_count(nodename,ctr):
    print 'bump counter to', ctr
    if ctr < 10:
      name = nodename.replace("XX", '0{0}'.format(str(ctr))) 
    else:
      name = nodename.replace("XX", '{0}'.format(str(ctr)))

    return name, ctr 

  cluster_members = {}    # dict of lists, {role: instancenames}

  iscluster = False

  if len(components) > 1:
    print "its a cluster!!"
    iscluster = True
  else:
    print 'its NOT a cluster'

  # NEED TO GET NAMES FIRST OF ALL COMPONENTS COLLECTIVELEY BECAUSE IT MAY BE A CLUSTER 

  _reservations_holder = []

  for component in components:

    _basename = '{0}-{1}-{2}'.format(c.product.lower(), component['role'].split('.')[1], component['pattern'])

    print '************** components role *************', component['role'], '\n', component, '\n'

    _instances = []
    nodectr = 1
    donectr = 0

    while donectr < int(component['nodes']):
      _name = _basename

      if c.RESIZEID > 0:
        _name = _basename.replace("CLUSTERID", 'clid-{0}'.format(str(c.RESIZEID)))

      if iscluster and ('role' in component) and ('{0}.cluster.id'.format(component['role']) in component['additionalgrains'][0]):
        _name = _basename.replace("CLUSTERID", 'clid-{0}'.format(str(component['additionalgrains'][0]['{0}.cluster.id'.format(component['role'])])))

      _a = _name.replace("REGION", c.region)
      _b = _a.replace("ENV", '{0}{1}'.format(c.pillarenv, c.nodename_suffix))
      if c.sandbox:
        holder = 'sandbox-{0}-{1}'.format(c.sandbox, _b)
        _b = holder
      if c.dte:
        holder = 'dte-{0}-{1}'.format(str(c.dte), _b)
        _b = holder
      if nodectr < 10:
        _c = _b.replace("XX", '0{0}'.format(str(nodectr))) #assumes max nodes of role = 99
      else:
        _c = _b.replace("XX", '{0}'.format(str(nodectr)))
      nodename = _c

      # ONCE NAME IS ESTABLISHED, CHECK FOR COUNTER INDEX IN EXISTING INSTANCES (PER ENVIRONMENT)
      # AND CHECK RESERVED NAMES (NAMES IN PROCESS UNDER OTHER CONDUCTOR EXECUTIONS)

      bumpctr = nodectr
      print 'existing_nodes', existing_nodes

      # TODO. THIS WILL LOOP INFINITLY IF YOU TRY TO CREATE A CLUSTER WITH A NODE NAME THAT DOES NOT USE THE 'XX' INDEX FORMAT AND EXISTS IN 
      # existing_nodes LIST.  
      # EXAMPLE: FOR NODES SUCH AS productgroup-product-primary.clid-1.fqdn
      # YOU MAY NOT WANT TO INDEX SINCE THERE CAN ONLY BE ONE PRIMARY FOR clid-1. THE INFINITE LOOP
      # IS A SIGN THAT AN INSTANCE EXISTS THAT SHOULD HAVE BEEN DESTROYED. 
      # HOWEVER, WE SHOULD EXIT OUT AFTER INDEX REACHES 1000 OR SOMETHING. 
      while ( (nodename in existing_nodes) or (nodename in _instances) or (bumpctr == 1000) or (os.path.isfile('{0}/{1}_{2}'.format(c.reserved_name_dir, c.pillarenv, nodename))) ):
        bumpctr+=1
        nodename, bumpctr = bump_count(_b,bumpctr)
      _c = nodename
      nodectr = bumpctr

      with open('{0}/{1}_{2}'.format(c.reserved_name_dir, c.pillarenv, _c), 'w') as f:
        f.write('{0}'.format(_c))
      _reservations_holder.append('{0}/{1}_{2}'.format(c.reserved_name_dir, c.pillarenv, _c))

      _instances.append(_c)

      if 'cluster-config' in component and component['iscluster'] == True:
        if component['role'] in cluster_members:
          cluster_members[component['role']].append(_c.encode('utf8'))
        else:
          cluster_members[component['role']] = _c.encode('utf8').split()

      donectr+=1
      nodectr+=1
      use_role = 'roleid'
      if len(components) > 1 or c.RESIZEID > 0:
        if component['iscluster'] == True:
          use_role = 'internalrole'

  print "cluster members\n"
  for k,v in cluster_members.iteritems():
    print k, v

  # delete placeholder name reservation files
  for n in _reservations_holder:
    try:
      os.remove(n)
    except Exception as e:
      print 'failed to remove placeholder reserved name file {0}'.format(n)
 

  for component in components:
    _instances = []
    nodectr = 1
    donectr = 0

    _basename = '{0}-{1}-{2}'.format(c.product.lower(), component['role'].split('.')[1], component['pattern'])

    while donectr < int(component['nodes']):
      _name = _basename

      if c.RESIZEID > 0:
        _name = _basename.replace("CLUSTERID", 'clid-{0}'.format(str(c.RESIZEID)))

      if iscluster and ('role' in component) and ('{0}.cluster.id'.format(component['role']) in component['additionalgrains'][0]):
        _name = _basename.replace("CLUSTERID", 'clid-{0}'.format(str(component['additionalgrains'][0]['{0}.cluster.id'.format(component['role'])])))
      _a = _name.replace("REGION", c.region)
      _b = _a.replace("ENV", '{0}{1}'.format(c.pillarenv, c.nodename_suffix))
      if c.sandbox:
        holder = 'sandbox-{0}-{1}'.format(c.sandbox, _b)
        _b = holder
      if c.dte:
        holder = 'dte-{0}-{1}'.format(str(c.dte), _b)
        _b = holder
      if nodectr < 10:
        _c = _b.replace("XX", '0{0}'.format(str(nodectr))) #assumes max nodes of role = 99
      else:
        _c = _b.replace("XX", '{0}'.format(str(nodectr)))
      nodename = _c

      # ONCE NAME IS ESTABLISHED, CHECK FOR COUNTER INDEX IN EXISTING INSTANCES (PER ENVIRONMENT)
      # AND CHECK RESERVED NAMES (NAMES IN PROCESS UNDER OTHER CONDUCTOR EXECUTIONS)

      bumpctr = nodectr  
      while ((nodename in existing_nodes) or (nodename in _instances) or (os.path.isfile('{0}/{1}_{2}'.format(c.reserved_name_dir, c.pillarenv, nodename))) ):
        bumpctr+=1
        nodename, bumpctr = bump_count(_b,bumpctr)
      _c = nodename
      nodectr = bumpctr

      with open('{0}/{1}_{2}'.format(c.reserved_name_dir, c.pillarenv, _c), 'w') as f:
        f.write('{0}'.format(_c))
      c.name_reservations.append('{0}/{1}_{2}'.format(c.reserved_name_dir, c.pillarenv, nodename))

      _instances.append(_c)
      print 'BUILDING NEW VM:', _c
  
      donectr+=1
      nodectr+=1
      component['names'] = _instances
      use_role = 'roleid'

      print component['iscluster'], component['role']
      if component['iscluster'] == True:     
        if len(components) > 1 or c.RESIZEID > 0:
          use_role = 'internalrole'
          if c.RESIZEID > 0:
            component['cluster_members'] = list(set(c.RESIZE_CLUSTER_MEMBERS))
          else:
            component['cluster_members'] = list(set(cluster_members[component['role']])) #removes duplicates

      _d = {}
      _d[component[use_role]] = component

      if _d not in c.PGROUP.new_cloud_build_xtra:
        c.PGROUP.new_cloud_build_xtra.append(_d)

  return True


def construct_conf_inputs(c, logger, name=None, subnet=None, secgroup=None):
  ''' 
  Pass instance of Conductor, logger 
  build dict with required values to pass when creating profile and provider
  inputs:
    name - required, unique name for task
    secgroup - secgroup to use
  '''
  if not name or not secgroup:
    logger.log('name and secgroup are required input', l.state.error)
    return {}

  amiimage = None
  try:
    amiimage = c.pillar_tree['config.common']['ami-image']['{0}'.format(c.region[:-1])]
  except:
    logger.log('Failed to find required ami in pillar', l.state.error)
    return {}

  # BUILD REQUIRED CONF INPUTS
  confmeta = {}
  confmeta['configname'] = name

  confmeta['subnet'] = subnet
  confmeta['security_group'] = secgroup

  confmeta['ami'] = amiimage

  if 'default-startup' in c.pillar_tree['config.common']:
    ds = c.pillar_tree['config.common']['default-startup']
    confmeta['default_start'] = ds
    c.productconf.default_startup = ds
    logger.log('setting default_startup {0}'.format(ds))
  else:
    confmeta['default_start'] = None


  print 'debug:\n', confmeta

  return confmeta

def create_map(c, logger, config_name, persist_volumes, networking):
  '''
  Parse class instance of Conductor.PRODUCT.new_cloud_build_xtra List of dict
  ref: 
    http://salt-cloud.readthedocs.org/en/latest/ref/cli/salt-cloud.html 
    https://docs.saltstack.com/en/latest/topics/cloud/map.html 
  We need to use cloud maps so we can dynamically set the role and other grains on each node.
  example:
  profilename:
    - machinename
      grains:
        foo: x
        role: xxxx
        other grains....
      minion:
        environment: xx
        startup_states: sls
        sls_list:
          - startupoverridexxx
  '''

  _base_roles = []

  _cluster_member_counters = {}

  for _rdata in c.PGROUP.new_cloud_build_xtra:
    print type(_rdata)
    for k,v in _rdata.iteritems():
      _base_roles.append(v['role'])


  if c.RESIZEID:
    _next_member_id = 1 #used in resize only
    _existing_member_ids = []
    for m in c.RESIZE_CLUSTER_MEMBERS:
      _mid = c.get_grain_value(m, 'cluster.member.id')
      if _mid:
        _existing_member_ids.append(_mid)

    for i in _base_roles:
      new_id_found = False
      while not new_id_found:
        if _next_member_id in _existing_member_ids:
          _next_member_id += 1
          continue
        else:
          new_id_found = True
      _cluster_member_counters[i] = _next_member_id
      _next_member_id += 1

  else:
    for i in _base_roles:
      _cluster_member_counters[i] = 2


  mapfilename = '{0}_{1}_{2}.map'.format(c.product.lower(), c.region, c.pillarenv)
  f = open('{0}/{1}'.format(c.mapdir,mapfilename), "w")
  profile_detected = False
  _instance_name_processed = []

  for _rdata in c.PGROUP.new_cloud_build_xtra:

    data = None
    data = _rdata

    if not data or not isinstance(data, dict):
      logger.log('Empty or invalid new_cloud_build_xtra property for createmap in {0}'.format(type(c)), logger.state.warning)
      return None

    _theprofiles = {}

    for x,y in data.items():

      pname = '{0}_{1}'.format(c.product.lower(), c.cpid)

      if pname in _theprofiles:
        values = _theprofiles[pname]
        values.append(y)
        _theprofiles[pname] = values
      else:
        tmplist = []
        tmplist.append(y)
        _theprofiles[pname] = tmplist

    def convert(data):
      if isinstance(data, basestring):
          return str(data)
      elif isinstance(data, collections.Mapping):
          return dict(map(convert, data.iteritems()))
      elif isinstance(data, collections.Iterable):
          return type(data)(map(convert, data))
      else:
          return data


    for profile,role_nodes in _theprofiles.items():
      if not profile_detected:
        f.write('{0}:\n'.format(profile))
        profile_detected = True

      for nl in role_nodes:
  
        #print '\nROLE_NODE:\n{0}'.format(nl)
        # n is node/instance name
        for n in nl['names']:
          _match = re.compile('^\D*(\d)\D*(\d)')
          for i in _match.findall(str(n)):
            x,y = i
          nodeindex = '{0}{1}'.format(str(x), str(y))
          if n in _instance_name_processed:
            continue
          f.write('  - {0}:\n'.format(n))
          _instance_name_processed.append(n)

          print 'new MINION to be: {0}'.format(n)

          # update global node array
          c.productconf.all_nodes.append(n)
          f.write('      size: {0}\n'.format(nl['size']))
          if nl['ami_override']:
            f.write('      image: {0}\n'.format(nl['ami_override']))
          # CHECK FOR VOLUME INFO AND EBS OPTIMIZED
          if 'ebs_optimize' in nl:
            f.write('      ebs_optimized: {0}\n'.format(nl['ebs_optimize']))

          if 'spot_config' in nl and 'spot_price' in nl['spot_config'] and nl['spot_config']['spot_price']:
            f.write('      spot_config:\n')
            f.write('        spot_price: {0}\n'.format(nl['spot_config']['spot_price']))
            f.write('        tag:\n') # always right Name and cpid tag
            f.write('          Name: {0}\n'.format(n))
            f.write('          ProvisionID: \"{0}\"\n'.format(str(c.cpid)))

            print nl['spot_config']
  
            if 'tag' in nl['spot_config'] and len(nl['spot_config']['tag']) > 0:
              if isinstance(nl['spot_config']['tag'], dict):
                for k,v in nl['spot_config']['tag'].iteritems():
                  f.write('          {0}: {1}\n'.format(k,v))
              else:
                logger.log('found type other than required dict when setting tags: {0} {1}'.format(t, type(t)), logger.state.warning) 

          '''
          security group and subnet in the role config context can only be private or public.
          so we need to look those types up in the networking dict that is passed in.
          if the sec group is specified the subnet MUST be specified in this map. The map
          will override the profile, and is salt-cloud finds the "network_interfaces" config in 
          the map, it will overwrite that entire config and thus any delta config in the profile
          will be lost. Therefore we MUST specify subnet of the role has security group setting, 
          must set security group if role has subnet. The region/zone defaults can be used so the role 
          doesn't have to have a config that it is not overriding.
          This logic does allow the role config to specify a private security group and public subnet
          and vice versa as long as they are on the same VPC. 
          This code may change after AWS networking architecture has been solidified.
          '''
   
          if 'security-group' in nl or 'subnet' in nl:
            f.write('      network_interfaces:\n')
            f.write('        - DeviceIndex: 0\n')

            if 'subnet' in nl:
              f.write('          SubnetId: {0}\n'.format(networking['{0}-subnet'.format(nl['subnet'].lower())]))
              f.write('          SecurityGroupId:\n')
              if 'security-group' in nl:
                f.write('            - {0}\n'.format(networking['{0}-security-group'.format(nl['security-group'].lower())]))
              else:
                # use same type (private|public) that the subnet is
                f.write('            - {0}\n'.format(networking['{0}-security-group'.format(nl['subnet'].lower())]))
            elif 'security-group' in nl:
              # here subnet is not role specific, so use type that sec group is
              f.write('          SubnetId: {0}\n'.format(networking['{0}-subnet'.format(nl['security-group'].lower())]))
              f.write('          SecurityGroupId:\n')
              f.write('            - {0}\n'.format(networking['{0}-security-group'.format(nl['security-group'].lower())]))

            f.write('          allocate_new_eip: False\n')

            '''
            associate ip address only if public.
            however until dns is setup or some other vpc config or sec grou/subnet config 
            to allow minion bootstrap to succeeed, we always need to give public ip
            '''           

            f.write('          AssociatePublicIpAddress: False\n')  #TODO make this a config option

          # UPDATE CONDUCTOR CLASS PROPERTY DICT WITH ALL USER DEFINED ROOT VOLUME TAGS
          # THIS IS USED WHEN THE BLOCK_DEVICE_MAPPINGS IS NOT BEING SET IN CLOUD CONFIG.
          # AWS WILL DEFAULT TO CREATE A ROOT DRIVE IF USER DOESN'T SPECIFY ANY BLOCK VOLUMES
          # THIS SETTING IS FOR CREATING TAGS ON THAT AUTO-CREATED ROOT VOLUME.
          # THE ALTERNATIVE IS TO SET BLOCK_DEVICE_MAPPINGS AND INCLUDE THE ROOT VOLUME.
          # IF THE ROT VOLUME, /sda IS NOT INCLUDED IN BLOCK_DEVICE_MAPPINGS, BUT YOU HAVE DEFINED
          # OTHER BLOCK VOLUMES, AWS WILL STILL CREATE THE ROOT VOLUME IN ADDITION.
       
          if 'root_volume_tags' in nl and len(nl['root_volume_tags']) > 0:
            c.productconf.root_volume_tags[n] = nl['root_volume_tags']

          # CHECK FOR BLOCK VOLUME OVERRIDE
          if 'block_volume_info' in nl:

            first_device = True
            root_in_block_config = False
            root_block_config_has_tags = False
            for _bv in nl['block_volume_info']:
              if '/dev/sda1' == convert(_bv)['device-name']:
                root_in_block_config = True
                if 'tag' in convert(_bv):
                  root_block_config_has_tags = True
      
            # block_volume_info is a List of unicode dict
            for _bv in nl['block_volume_info']:
            
              bvi = convert(_bv)
              _block_vol_size = None
              _block_vol_type = None
              _block_dev_name = None
              _block_dev_tags = {}

              if 'device-name' in bvi and bvi['device-name']:
                _block_dev_name = bvi['device-name']
             
              if 'volume-size' in bvi and bvi['volume-size']:
                _block_vol_size = bvi['volume-size']

              if 'volume-type' in bvi and bvi['volume-type']:
                _block_vol_type = bvi['volume-type']

              if 'tag' in bvi and isinstance(bvi['tag'], dict) and len(bvi['tag']):
                _block_dev_tags = bvi['tag']
              
                # IF TAGS ARE DEFINED FOR RESERVED AWS ROOT DEVICE WE DO NOT NEED TO SPECIFY ROOT DEVICE TAGS SET ABOVE IN c.productconf.root_volume_tags
                if root_in_block_config and root_block_config_has_tags:
                  c.productconf.root_volume_tags = {} #reset to none and use the tags in block_device_mappings
                  if 'name' not in bvi['tag']:
                    c.productconf.root_volume_tags[n] = {'name': str(n)} #required default
                  if 'ProvisionID' not in bvi['tag']:
                    c.productconf.root_volume_tags[n] = {'ProvisionID': '{0}'.format(str(c.cpid))} #required default

              else:
                _block_dev_tags = {'Name': str(n)}
                _block_dev_tags = {'ProvisionID': '{0}'.format(str(c.cpid))}

              if _block_vol_size or _block_vol_type and _block_dev_name:
                if first_device:
                  f.write('      block_device_mappings:\n')
                  first_device = False
                f.write('        - DeviceName: {0}\n'.format(_block_dev_name))
                if _block_vol_size:
                  f.write('          Ebs.VolumeSize: {0}\n'.format(_block_vol_size))
                if _block_vol_type:
                  f.write('          Ebs.VolumeType: {0}\n'.format(_block_vol_type))
                f.write('          tag:\n')
                if _block_dev_tags:
                  _tags = convert(_block_dev_tags) #DICT
                  if 'Name' not in _tags:
                    _tags['Name'] = str(n)
                  if 'ProvisionID' not in _tags:
                    _tags['ProvisionID'] = '{0}'.format(str(c.cpid))

                  for tag_key, tag_val in _tags.iteritems():
                    f.write('            {0}: {1}\n'.format(tag_key, tag_val))
                else:
                  f.write('            Name: {0}\n'.format(str(n)))
                  f.write('            ProvisionID: {0}\n'.format(str(c.cpid)))

          if 'persist_volumes' in nl: #if we set at instance config level
            if str(nl['persist_volumes']).lower() == "true":
              f.write('      del_all_vols_on_destroy: False\n')
              f.write('      del_root_vol_on_destroy: False\n')
            else:
              f.write('      del_all_vols_on_destroy: True\n')
              f.write('      del_root_vol_on_destroy: True\n')
          else: #check common config
            if 'persist-volumes' in c.pillar_tree['config.common'] and (str(c.pillar_tree['config.common']['persist-volumes']).lower() == "true"):
              f.write('      del_all_vols_on_destroy: False\n')
              f.write('      del_root_vol_on_destroy: False\n')
            else:
              f.write('      del_all_vols_on_destroy: True\n')
              f.write('      del_root_vol_on_destroy: True\n')

          '''
          THIS WILL BE A LIST, WITH DICT ENTRIES
          volumes:
          - { size: 20, device: /dev/sdf, type: io1, iops: 600 }
          - { size: 100, device: /dev/sdh, type: io1, iops: 1000 }
          '''
          if 'volume_info' in nl:
            f.write('      volumes:\n')
            for vol in nl['volume_info']:
              _tags = {}
              _tags['Name'] = str(n)
              _tags['ProvisionID'] = str(c.cpid)
              _volinfo = {}
              try:
                _volinfo['size'] = convert(nl['volume_info'][vol]['size'])
                _volinfo['device'] = convert(nl['volume_info'][vol]['device'])
                _volinfo['type'] = convert(nl['volume_info'][vol]['type'])
                ''' OPTIONAL '''
                if 'iops' in  nl['volume_info'][vol]:
                  _volinfo['iops'] = convert(nl['volume_info'][vol]['iops'])
                if 'encrypted' in  nl['volume_info'][vol]:
                  _volinfo['encrypted'] = convert(nl['volume_info'][vol]['iops'])
                if 'tags' in nl['volume_info'][vol]:
                  _tags = convert(nl['volume_info'][vol]['tags']) #DICT
                  _tags['ProvisionID'] = str(c.cpid)
                  _tags['Name'] = str(n)
                _volinfo['tags'] = _tags
              except:
                logger.log('volume {0} missing required configuration item. size, type, device, and iops needed'.format(vol), l.state.error)
           
              holder = []
              holder.append('{')
              _volinfo['Name'] = str(n)
              _volinfo['ProvisionID'] = str(c.cpid)
              for k,v in _volinfo.iteritems():
                holder.append(' {0}: {1},'.format(k,v))
              holder.append(' }')

              f.write('        - {0}\n'.format(''.join(holder)))


          f.write('      minion:\n')
          f.write('        environment: {0}\n'.format(c.env))
          saltmasters = c.pillar_tree['{0}'.format(c.region[:-1])]['salt_master']
          if isinstance(saltmasters, list):
            f.write('        master:\n')
            for sm in saltmasters:
              f.write('      - {0}\n'.format(sm))
            f.write('        master_type: failover\n')
          else:
            f.write('        master: {0}\n'.format(c.pillar_tree['{0}'.format(c.region[:-1])]['salt_master']))
          f.write('        pillarenv: {0}\n'.format(c.pillarenv))

          _the_delaystate = []

          # CHECK FORCE DELAY STATE
          # STARTUPOVERRIDE IS A LIST []
          if 'force_delay_state' in nl and nl['force_delay_state'] == True:

            print '**** FORCE DELAY STATE .....\n'

            f.write('        startup_states: sls\n')
            f.write('        sls_list:\n')
            f.write('          - force-delay-state\n')
            if nl['startupoverride']:
              for so in nl['startupoverride']:
                _the_delaystate.append(so)
            else:
                if c.productconf.default_startup:
                  _the_delaystate.append(c.productconf.default_startup)
          else:
            if nl['startupoverride']:
              f.write('        startup_states: sls\n')
              f.write('        sls_list:\n')
              for so in nl['startupoverride']:
                f.write('          - {0}\n'.format(so))

          if _the_delaystate:
            _delaystate = {}
            _delaystate[n] = _the_delaystate

            c.productconf.delaystates.append(_delaystate)

          f.write('      grains:\n')
          f.write('        cpid: {0}\n'.format(c.cpid))
          if c.issystem:
            f.write('        {0}.system.id: {1}\n'.format(c.product.lower(), c.SYSTEMID))
            f.write('        {0}.system.name: {1}\n'.format(c.product.lower(), c.SYSTEMNAME))
            f.write('        cloud.system.id: {0}\n'.format(c.CLOUDSYSTEMID))
          f.write('        node.index: {0}\n'.format(nodeindex))
          f.write('        role: {0}\n'.format(nl['role']))
          if c.sandbox:
            f.write('        sandbox: True\n')
          if int(c.dte) > 0:
            f.write('        dte: {0}\n'.format(str(c.dte)))

          productgroup_override = False
          pillarenv_override = False
          if 'additionalgrains' in nl:

            for g in nl['additionalgrains']:
              if isinstance(g, dict):
                for k,v in g.iteritems():
                  if k == 'product.group':
                    productgroup_override = True
                  if k == 'pillar.environment':
                    pillarenv_override = True
                  f.write('        {0}: {1}\n'.format(k,v))
              else:
                logger.log('found type other than required dict when setting grains: {0} {1}'.format(g, type(g)), logger.state.warning)

          if not productgroup_override:
            f.write('        product.group: {0}\n'.format(c.product.lower()))
          if not pillarenv_override:
            f.write('        pillar.environment: {0}\n'.format(c.pillarenv))

          if 'roleid' in nl:
            f.write('        role.id: {0}\n'.format(nl['roleid']))
          if nl['baserole']:
            f.write('        role.base: {0}\n'.format(nl['baserole']))

          # COMPOSITEROLE IS A LIST []
          if nl['compositerole']:
            f.write('        composite.role: {0}\n'.format(nl['compositerole']))

          if 'internalrole' in nl:
            f.write('        internal.role: {0}\n'.format(nl['internalrole']))

            if nl['internalrole'] == 'primary':
              f.write('        cluster.member.id: 1\n')
            elif not nl['internalrole'] == None:
              for k,v in _rdata.iteritems():
                _role_of_key = v['role']
              f.write('        cluster.member.id: {0}\n'.format(_cluster_member_counters[_role_of_key]))
              _cluster_member_counters[_role_of_key] += 1

          
          # cluster_members IS A DICT IF LISTS []
          if 'cluster_members' in nl:
            f.write('        cluster.members: {0}\n'.format(nl['cluster_members']))
            f.write('        cluster.location: {0}\n'.format(c.region))

          f.write('        node_location: {0}\n'.format(c.region))

          #always write Name and ProvisionID tag even if nothing is user defined
          f.write('      tag:\n')
          f.write('        Name: {0}\n'.format(n))
          f.write('        ProvisionID: \"{0}\"\n'.format(str(c.cpid)))
          if 'tags' in nl and len(nl['tags']) > 0:
            for t in nl['tags']:
              if isinstance(t, dict):
                for k,v in t.iteritems():
                  f.write('        {0}: {1}\n'.format(k,v))
              else:
                logger.log('found type other than required dict when setting tags: {0} {1}'.format(t, type(t)), logger.state.warning) 


  f.close()

  for i in c.productconf.all_nodes:
    print 'new instance ---', i


  #logger.log('\n\nMAP FILE CONTENT:\n\n')
  #with open('{0}/{1}'.format(c.mapdir,mapfilename), 'r') as content:
  #  print content.read()

  return '{0}/{1}'.format(c.mapdir,mapfilename)


def get_active_roles(c, names):
  '''
  Input:
  Condcutor class instance
  List of instance Names to get roles from
  
  Assumes the input name (instance name) has already been qualified against a product.group
  Returns a List of roles (excluding productgroup prefix if exists)
  '''
  active_roles = []
  for n in names:
    composite_role = c.get_grain_value(minion=n, key='composite.role')
    if composite_role and isinstance(composite_role, list):
      for r in composite_role:
        if '.' in r and c.product.lower() == r.split('.')[0]: 
          active_roles.append(r.split('.')[1])
        else:
          active_roles.append(r)
    else:
      role = c.get_grain_value(minion=n, key='role')
      if role:
        if '.' in role and c.product.lower() == role.split('.')[0]: 
          active_roles.append(role.split('.')[1])
        else:
          active_roles.append(role)

  return active_roles  


def get_active_productgroup_roles(c, names):
  '''
  Input:
  Condcutor class instance
  List of instance Names to get roles from
  
  Assumes the input name (instance name) has already been qualified against a product.group
  Returns a List of roles 
  '''
  active_roles = []
  for n in names:
    composite_role = c.get_grain_value(minion=n, key='composite.role')
    if composite_role and isinstance(composite_role, list):
      for r in composite_role:
        active_role.append(r)
    else:
      role = c.get_grain_value(minion=n, key='role')
      if role:
        active_roles.append(role)

  return active_roles  


def get_destroyable_instances(cmdargs, c):

  ''' 
  cmdargs must have either grain= or role= or node=
  when filtering on node, substring matches are valid
  when filtering on grain role, substring matches are valid
  when filtering on grain composite.role, substring matches are NOT valid
  when filtering on grain parameter argument, match must be exact
  when DOWNSIZING we set the grain in cmdargs (which shouldnt already exist) to productgroup.role.cluster.id

  Return: dict {instanceid: Name}
  '''

  # GET MANAGED MINION LIST TO AVOID QUERIES WHERE SALT ALWAYS OUTPUTS 
  managed_up_minions = get_up_minions()

  _ids = []  
  id_name_map = {}
  
  for i in awsc.get_aws_instance_map(awsconnector=c.AWS_CONNECT):

    if i and managed_up_minions and i.items()[0][1] in managed_up_minions:

      #print '{0}--------{1}'.format(i.items()[0][0], i.items()[0][1])
      pg = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key='product.group')

      if pg and c.product.lower() == pg:

        # ---------------- NEW CODE ADDED TO IMPLEMENT DOWNSIZE ACTION
        if 'action' in cmdargs and cmdargs['action'] == 'downsize':

          found_destroyable_member = False

          if 'node' in cmdargs:
            if i.items()[0][1] and i.items()[0][1] == cmdargs['node']:
              found_destroyable_member = True
            else:
              continue
          else:
            _role = cmdargs['role']
            if '.' in cmdargs['role']:
              _role = cmdargs['role'].split('.')[1]
            _key = '{0}.{1}.cluster.id'.format(pg, _role)

            id_value = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key=_key)
            _matchid = cmdargs['clusterid']
            _matchinternalrole = cmdargs['internalrole']

            if id_value and id_value == _matchid:
              int_role_value = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key='internal.role')
              print 'matching internal.role', int_role_value, _matchinternalrole

              if int_role_value and int_role_value == _matchinternalrole:
                found_destroyable_member = True

          if found_destroyable_member:

            _members = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key='cluster.members')
            if _members and (i.items()[0][1] in _members):
              _members.remove(i.items()[0][1])
              for m in _members:
                c.RESIZE_CLUSTER_MEMBERS.append(m)

            _ip = c.get_grain_value(i.items()[0][1], 'ipv4')
            if _ip and isinstance(_ip, list):
              c.DOWNSIZE_MEMBER_IP = _ip[0]
 
            _members_ip = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key='cluster.members.ip')
            print 'members_ip for node {0}'.format(i.items()[0][1])
            if _members_ip and c.DOWNSIZE_MEMBER_IP in _members_ip:
              _members_ip.remove(c.DOWNSIZE_MEMBER_IP)
              for ip in _members_ip:
                c.RESIZE_CLUSTER_MEMBERS_IP.append(ip)

            print 'matched the member....', i.items()[0][0], i.items()[0][1]
            return {convert(i.items()[0][0]): convert(i.items()[0][1])}

        # --------------------------------------------------------------

        if 'role' in cmdargs:
          # GRAIN FILTER
          val = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key='role')
          if val and '{0}.{1}'.format(c.product.lower(),cmdargs['role']) == val or cmdargs['role'] == 'all':
            _ids.append(i.items()[0][0])
            if i.items()[0][1]:
              id_name_map[convert(i.items()[0][0])] = convert(i.items()[0][1])
            else:
              id_name_map[convert(i.items()[0][0])] = 'no-name-tag'

          val = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key='composite.role')
          if val and isinstance(val, list):
            if cmdargs['role'] in val or cmdargs['role'] == 'all':
              _ids.append(i.items()[0][0])
              if i.items()[0][1]:
                id_name_map[convert(i.items()[0][0])] = convert(i.items()[0][1])
              else:
                id_name_map[convert(i.items()[0][0])] = 'no-name-tag'

        elif 'node' in cmdargs:
          # NODE NAME FILTER
          if cmdargs['node'] in str(i.items()[0][1]):
            _ids.append(i.items()[0][0])
            if i.items()[0][1]:
              id_name_map[convert(i.items()[0][0])] = convert(i.items()[0][1])
            else:
              id_name_map[convert(i.items()[0][0])] = 'no-name-tag'

        elif 'grain' in cmdargs:
          _key = None
          _value = None
          print cmdargs['grain']
          print type(cmdargs['grain'])

          for k,v in cmdargs['grain'].iteritems():
            _key = k
            _value = v
          val = c.get_grain_value(minion='{0}'.format(i.items()[0][1]), key=_key)
          if val and _value == val:
            _ids.append(i.items()[0][0])
            if i.items()[0][1]:
              id_name_map[convert(i.items()[0][0])] = convert(i.items()[0][1])
            else:
              id_name_map[convert(i.items()[0][0])] = 'no-name-tag'
        else:
          pass


  if 'action' in cmdargs and cmdargs['action'] == 'downsize':
    # we get here when user passed in invalid clusterid or internalrole
    return {}

  if not _ids:
    print "no nodes found to terminate"

  return id_name_map




def destroy_instances(_ids, c):

  '''
  input: instance of Conductor class
  return: True | False
  '''
  if not isinstance(_ids, dict):
    return False
  
  print 'instance ready for destroy.......'

  for k,v in _ids.iteritems():
    print k, v


  ids = [k for k,v in _ids.iteritems()]
  _names = [v for k,v in _ids.iteritems()]

  results = c.AWS_CONNECT.terminate_instances(instance_ids=ids)
  _removed = [] #WAIT FOR TERMINATED STATUS
  sys.stdout.flush()
  while _names:
    sys.stdout.write('. ')
    sys.stdout.flush()
    for i in awsc.get_aws_instance_map(awsconnector=c.AWS_CONNECT):
      if i:
        for n in _names:
          status = None
          if n == i.items()[0][1]:
            status = awsc.get_instance_status(awsconnector=c.AWS_CONNECT, id=i.items()[0][0])
            if status == 'terminated':
              _names.remove(n)
              _removed.append(n)
              print '\nremoving {0} has reached terminated status'.format(n)
    time.sleep(3)

  results = c.delete_keys_from_list(minion=_removed) # DELETE SALT MINION KEYS

  print results

  return True



def check_infrastructure_overrides(c, public_secgrp=None, private_secgrp=None, public_subnet=None, private_subnet=None):
  '''
  Finds and maps vpc to subnet and sec group id's
  return data is used to create the cloud provider and profiles
 
  input:
  conductor class
  public_secgrp
  private_secgrp
  public_subnet
  private_subnet

  return:
  true|false, same or modified public_secgrp, private_secgrp, public_subnet, private_subnet
  '''

  if c.vpcid or c.dte:
    if c.vpcid:
      vpcid = c.vpcid

      #match to the vpc Name tag after looking it up by ID, needed to find the subnet and secgroup for the passed in vpc
      vpcname = None
      import boto.vpc
      conn = boto.vpc.connect_to_region(c.region[:-1])
      tags = conn.get_all_tags()
      for t in tags:
        # MIGHT NEED TO RESET VPC IF dte=X PASSED IN
        if c.dte:
          if t.value == 'DTE-{0}-{1}'.format(c.pillarenv.upper(), str(c.dte)):
            print 'found DTE vpc', t.value, t.res_id
            vpcid = t.res_id
            vpcname = t.value
        else:   
          if t.res_id == vpcid:
            print t.name, 'vpc resource ID found', t.res_id
            vpcname = t.value 


      if not vpcname:
        logger.log('failed to find vpcId. If not passing vpc parameter, check the default environment vpc, subnets and security groups in pillar', logger.state.error)
        return False, public_secgrp, private_secgrp, public_subnet, private_subnet

      # DO NOT CREATE SANDBOX IN DTE'S        
      if vpcname and vpcname.startswith('DTE-') and c.sandbox:
        logger.log('Cannot create sandbox in DTE vpc\'s, abort.', logger.state.error)
        return True, public_secgrp, private_secgrp, public_subnet, private_subnet 

      for t in tags:
        if t.value:
          if c.sandbox:
            # could only be default ENV here (no sandbox in DTE)
            if vpcname in t.value and '-SB-Public' in t.value and 'subnet-' in t.res_id:
              print 'found sandbox public subnet:', t.value, t.res_id
              public_subnet = t.res_id

            if vpcname in t.value and '-SB-Private' in t.value and 'subnet-' in t.res_id:
              print 'found sandbox private subnet:', t.value, t.res_id
              private_subnet = t.res_id

            if vpcname in t.value and '-SB-Public' in t.value and 'sg-' in t.res_id:
              print 'found sandbox public security group:', t.value, t.res_id
              public_secgrp = t.res_id

            if vpcname in t.value and '-SB-Private' in t.value and 'sg-' in t.res_id:
              print 'found sandbox private security group:', t.value, t.res_id
              private_secgrp = t.res_id
          else:
            if c.dte > 0:
              if vpcname in t.value and '-VMI-Public' in t.value and 'subnet-' in t.res_id:
                print '\n*** setting dte public subnet to', t.res_id, t.value
                public_subnet = t.res_id

              if vpcname in t.value and '-VMI-Private' in t.value and 'subnet-' in t.res_id:
                print '\n*** setting dte private subnet to', t.res_id, t.value
                private_subnet = t.res_id
          
              if vpcname in t.value and '-VMI-Public' in t.value and 'sg-' in t.res_id:
                public_secgrp = t.res_id
                print '\n*** setting env public secgroup to', t.res_id, t.value

              if vpcname in t.value and '-VMI-Private' in t.value and 'sg-' in t.res_id:
                private_secgrp = t.res_id
                print '\n*** setting dte private secgroup to', t.res_id, t.value

            else:

              if vpcname in t.value and '{0}-VMI-Public'.format(c.pillarenv.upper()) in t.value and 'subnet-' in t.res_id:
                public_subnet = t.res_id
                print '\n*** setting env public subnet to', t.res_id, t.value

              if vpcname in t.value and '{0}-VMI-Private'.format(c.pillarenv.upper()) in t.value and 'subnet-' in t.res_id:
                private_subnet = t.res_id
                print '\n*** setting env private subnet to', t.res_id, t.value

              if vpcname in t.value and '{0}-VMI-Public'.format(c.pillarenv.upper()) in t.value and 'sg-' in t.res_id:
                public_secgrp = t.res_id
                print '\n*** setting env public secgroup to', t.res_id, t.value

              if vpcname in t.value and '{0}-VMI-Private'.format(c.pillarenv.upper()) in t.value and 'sg-' in t.res_id:
                private_secgrp = t.res_id
                print '\n*** setting env private secgroup to', t.res_id, t.value

  return True, public_secgrp, private_secgrp, public_subnet, private_subnet

def verify_pillar_requirements(c):

  '''
  input: instance of Conductor class
  return: True|False
  '''

  # PILLAR REQUIREMENTS
  if not c.region[:-1] in c.pillar_tree:
    logger.log('Cannot find region {0} pillar data, make sure your pillar is in environment {1}'.format(c.region, \
                                                                                   c.pillarenv), logger.state.error)
    return False

  if not 'id' in c.pillar_tree[c.region[:-1]]: 
    logger.log('Cannot find region {0} AIM id pillar data, make sure your pillar is in environment {1}'.format(c.region, \
                                                                                   c.pillarenv), logger.state.error)
    return False

  if not 'key' in c.pillar_tree[c.region[:-1]]: 
    logger.log('Cannot find region {0} AIM key pillar data, make sure your pillar is in environment {1}'.format(c.region, \
                                                                                   c.pillarenv), logger.state.error)
    return False

  if not 'management-vpc' in c.pillar_tree[c.region[:-1]]: 
    logger.log('Cannot find region {0} management-vpc pillar data, make sure your pillar is in environment {1}'.format(c.region, \
                                                                                   c.pillarenv), logger.state.error)
    return False

  return True

def get_default_subnets(c, logger=None):
  '''
  input: Conductor class instance
         optional logger class
  return: public subnetId, private subnetId OR None 
  '''

  # DEFAULT ALL TO PUBLIC SUBNET. OVERRIDE AT THE ROLE LEVEL CONFIG
  public_subnet = None
  private_subnet = None

  logging = True

  if not logger:
    logging = False

  try:
    if c.pillar_tree['{0}'.format(c.region[:-1])]['subnet']['public']['availability']['zone_{0}'.format(c.region[-1:])]:
      public_subnet = c.pillar_tree['{0}'.format(c.region[:-1])]['subnet']['public']['availability']['zone_{0}'.format(c.region[-1:])]  
  except:
    if logging:
      logger.log('Failed to find public_subnet in pillar', logger.state.warning)

  try:
    if c.pillar_tree['{0}'.format(c.region[:-1])]['subnet']['private']['availability']['zone_{0}'.format(c.region[-1:])]:
      private_subnet = c.pillar_tree['{0}'.format(c.region[:-1])]['subnet']['private']['availability']['zone_{0}'.format(c.region[-1:])]
  except:
    if logging:
      logger.log('Failed to find private_subnet in pillar', logger.state.warning)

  return public_subnet, private_subnet

def get_default_security_groups(c, logger=None):
  '''
  input: Conductor class instance
         optional logger class
  return: management groupid, public group Id, private group Id OR None, None, None
  '''

  # SEC GROUP SHOULD BE ID
  mgmt_secgrp = None
  public_secgrp = None
  private_secgrp = None
  
  logging = True

  if not logger:
    logging = False
  try: 
    if c.pillar_tree['{0}'.format(c.region[:-1])]['security-group']['management']: 
      mgmt_secgrp = c.pillar_tree['{0}'.format(c.region[:-1])]['security-group']['management']
  except:
    if logging:
      logger.log('Failed to find management security-group in pillar, cannot continue', logger.state.error)
    return mgmt_secgrp, public_secgrp, private_secgrp

  try: 
    if c.pillar_tree['{0}'.format(c.region[:-1])]['security-group']['public']: 
      public_secgrp = c.pillar_tree['{0}'.format(c.region[:-1])]['security-group']['public']

  except:
    if logging:
      logger.log('Failed to find public security-group in pillar', logger.state.warning)

  try: 
    if c.pillar_tree['{0}'.format(c.region[:-1])]['security-group']['private']: 
      private_secgrp = c.pillar_tree['{0}'.format(c.region[:-1])]['security-group']['private']
  except:
    if logging:
      logger.log('Failed to find private security-group in pillar', logger.state.warning)

  if not public_secgrp:
    # DEFAULT TO USE MANAGEMENT
    public_secgrp = mgmt_secgrp

  return mgmt_secgrp, public_secgrp, private_secgrp


def create_load_balancer(c, role, instances=[], subnets=[], secgroups=[], name=None, type=None):
  '''  
  Configures and creates the elb

  type - elb | elbv2 string

  example pillar for role config

    elb:
      interval: 10
      timeout: 5
      healthy_threshold: 2
      unhealthy_threshold: 4
      target: /health
      forwarding_port: 80
      scheme: internet-facing | internal

  '''
  if not subnets or not name:
    print 'subnets and name required'
    return False, None 

  product_group = c.pillar_tree['{0}.role'.format(c.product.lower())]

  hc = {}  
  
  if str(type) in product_group[role]:
    elb_object = product_group[role][type]

  else:
    logger.log('failed to locate elb in pillar for {0}'.format(role))
    return False, None 

  scheme = 'internet-facing' #default

  if 'scheme' in product_group[role][type]:
    scheme = product_group[role][type]['scheme']

  # int first
  dataset = ['interval', 'timeout', 'healthy_threshold', 'unhealthy_threshold']
  for d in dataset:
    if d in elb_object:
      hc[d] = int(elb_object[d])

  dataset = []  

  dataset = ['target', 'forwarding_port']
  for d in dataset:
    if d in elb_object:
      hc[d] = elb_object[d]

  #_subnets = subnets.split()

  if type == 'elb':
    logger.log('calling aws create_elastic_load_balancer for {0}'.format(name))
    results, lb = awsc.create_elastic_load_balancer(region=c.region[:-1], \
                                               name='{0}-{1}'.format(name, c.pillarenv), \
                                               zones=c.region.split(), \
                                               subnets=subnets, \
                                               security_groups=secgroups, \
                                               hc=hc, \
                                               instances=instances, \
                                               scheme=scheme)

    logger.log('awsc.create_elastic_load_balancer() returned:\n{0} {1}'.format(results, lb))
 
  else:
    logger.log('future....call aws create elbv2 here.....')
    results = None
    lb = None

  return results, lb



def check_load_balancer_data(c, security_group_id=None, subnets=[]):
  '''  
  iterates the list of vm's being created and determines if they need to be behind the default public or private elb
  calls create load balancer function once per app set as needed.

  MUST be called once after aws cloud provisioning

  THIS IS BEING UPDATE TO SUPPORT elbv2 AS WELL
  '''

  _nodes = []  

  print '\n\n**********\ncheck_load_balancer_data\n*********\n\n'
  #return _nodes


  product_group = c.pillar_tree['{0}.role'.format(c.product.lower())]

  def _process_role_set(c, role):
    '''
    role should be a role that has alreday been confirmed to have elb or elbv2 config in pillar by the caller function
    '''
    _nodes = []

    new_cloud_build_xtra = c.PGROUP.new_cloud_build_xtra

    print '\ngetting role {0} instances that need elb\n'.format(role)

    for group_role in new_cloud_build_xtra:
      if '{0}.{1}'.format(c.product.lower(), role) in group_role:
        for n in group_role['{0}.{1}'.format(c.product.lower(), role)]['names']:
          _nodes.append(n)

    return _nodes

  def _config_load_balancer(c, role, _nodes, security_group_id, subnets, elb_name, isclassic):

    '''
    first token in elb_name, dash delimiter, is the role (has been modified to replace _ for -
    isclassic - True | False for elb classic
 
    '''
    print 'debug: in config_load_balancer'
    elb_instances = []    
    secgroup_list = None
    if security_group_id:
      secgroup_list = security_group_id.split()
    # get instance ID for the node
    for nodemeta in c.productconf.node_meta:
      for k,v in nodemeta.items():
        print 'debug: checking elb status for', str(k)
        if k in _nodes:
          if not 'instance_id' in v:
            print 'something happened, no instance_id for {0}'.format(k)
            break
          else:
            elb_instances.append(v['instance_id'])
          print 'creating/adding to elb {0}, instances {1}'.format(elb_name, elb_instances)
          if elb_instances:
            print 'debug: calling create_load_balancer', elb_instances
            _type = 'elbv2'

            if isclassic:
              _type = 'elb'
            print 'DEBUG....calling create_load_balancer for type {0}'.format(_type)
            results, newlb = create_load_balancer(c, \
                                                  role, \
                                                  instances=convert(elb_instances), \
                                                  subnets=subnets, \
                                                  secgroups=secgroup_list, \
                                                  name=elb_name, \
                                                  type=_type)

            print 'create_load_balancer() returned {0} {1}'.format(results, newlb)
    #need to add error checking and return True or False
    return True

  # once per app that needs elbs
  for r in c.pillar_tree['{0}.role'.format(c.product.lower())]['all']: 
    if ('elb' in c.pillar_tree['{0}.role'.format(c.product.lower())][r]) and ('name' in c.pillar_tree['{0}.role'.format(c.product.lower())][r]['elb']):

      print 'debugging: has elb config.....', r

      elb_name = c.pillar_tree['{0}.role'.format(c.product.lower())][r]['elb']['name']
      _nodes = _process_role_set(c, r)
      if _nodes:
         print "need to create load balancer...."
         print "TODO need to check code to see if we skip creating lb if exists rather than just try to create it."

         results = _config_load_balancer(c, r, _nodes, security_group_id, subnets, '{0}-{1}'.format(elb_name, c.region[:-1]), True)
    if ('elbv2' in c.pillar_tree['{0}.role'.format(c.product.lower())][r]) and ('name' in c.pillar_tree['{0}.role'.format(c.product.lower())][r]['elbv2']):
      elb_name = c.pillar_tree['{0}.role'.format(c.product.lower())][r]['elbv2']['name']
      _nodes = _process_role_set(c, r)
      if _nodes:
         print "need to create elbv2 load balancer....."
         results = _config_load_balancer(c, r, _nodes, security_group_id, subnets, '{0}-{1}'.format(elb_name, c.region[:-1]), False)

  return True # or false if problems


def next_clusterid(c, isgroup, role, minion=None):
  '''
  input: 
    class instance of conductor
    isgroup specific boolean
    role 
    minion filter

  creates reservation files in the following format:
  (default directory /srv/runners/reserved_ids/)
  ENV_grain  

  Returns:
  True | False, id
  '''
  newid = 1
  key = None
  if isgroup:
    key = '{0}.{1}.cluster.id'.format(c.product.lower(), role)
  else:
    key = 'cloud.{0}.cluster.id'.format(role)

  grains = c.client.cmd(minion, 'grains.items', tgt_type="compound")

  used_ids = []
 
  for n,m in grains.iteritems():
    if isinstance(m, dict):
      if key in m and m[key]:
        used_ids.append(int(m[key]))

  while newid < 500:
    if newid in used_ids:
      newid+=1 
    else:
      # CHECK RESERVED
      if isgroup:
        _file = '{0}/{1}_{2}.{3}.cluster.id.{4}'.format(c.reserved_id_dir, c.pillarenv, c.product.lower(), role, newid)
      else:
        _file = '{0}/{1}_cloud.{2}.cluster.id.{3}'.format(c.reserved_id_dir, c.pillarenv, role, newid)
      if os.path.isfile(_file):
        newid+=1
      else:
        with open(_file, 'w') as f:
          f.write('{0}'.format(newid))
        c.id_reservations.append(_file)
        break

  print 'next available clusterid is ready - {0}'.format(newid)
  return True, newid

def next_systemid(c, isgroup,  minion=None):
  '''
  input: 
    class instance of conductor
    isgroup specific boolean
    minion filter

  creates reservation files in the following format:
  (default directory /srv/runners/reserved_ids/)
  ENV_grain  

  Returns:
  True | False, id
  '''
  newid = 1
  key = None
  if isgroup:
    key = '{0}.system.id'.format(c.product.lower())
  else:
    key = 'cloud.system.id'

  grains = c.client.cmd(minion, 'grains.items', tgt_type="compound")

  used_ids = []
  for n,m in grains.iteritems():
    if isinstance(m, dict):
      if key in m and m[key]:
        used_ids.append(int(m[key]))

  while newid < 800:
    if newid in used_ids:
      newid+=1 
    else:
      # CHECK RESERVED
      if isgroup:
        _file = '{0}/{1}_{2}.system.id.{3}'.format(c.reserved_id_dir, c.pillarenv, c.product.lower(), newid)
      else:
        _file = '{0}/{1}_cloud.system.id.{2}'.format(c.reserved_id_dir, c.pillarenv, newid)
      if os.path.isfile(_file):
        newid+=1
      else:
        with open(_file, 'w') as f:
          f.write('{0}'.format(newid))
        c.id_reservations.append(_file)
        break

  print 'next available system id is ready - {0}'.format(newid)
  return True, newid


def available_systemid(c, isgroup, sysid, minion=None):
  '''
  int compare PRODUCTGROUP.system.id grain values and return False if any minion is found with same value in the environment 
  Input:
  Conductor class instance
  isgroup boolean  
  user input sysid
  minion - filtered minion target

  creates reservation files in the following format:
  (default directory /srv/runners/reserved_ids/)
  ENV_grain  

  Returns: 
  True if passed in value is NOT used, False if passed value is used 
  '''

  key = None
  if isgroup:
    key = '{0}.system.id'.format(c.product.lower())
    c.logger.log('checking for {0}.system.id {1}'.format(c.product.lower(), sysid))
  else:
    raise ValueError('user cannot specified cloud.system.id, this is autogenerated based on the current environment')

  if not sysid > 0:
    raise ValueError("user specified SYSTEMID must be greater than 0.")

  grains = c.client.cmd(minion, 'grains.items', tgt_type="compound")

  used_ids = []
  for n,m in grains.iteritems():
    if isinstance(m, dict):
      if key in m and m[key]:
        used_ids.append(int(m[key]))

  if sysid in used_ids:
    return False

  # CHECK RESERVED
  _file = '{0}/{1}_{2}.system.id.{3}'.format(c.reserved_id_dir, c.pillarenv, c.product.lower(), sysid)
  if os.path.isfile(_file):
    return False
  else:
    with open(_file, 'w') as f:
      f.write('{0}'.format(sysid))
    c.id_reservations.append(_file)
    return True

  print 'next available system id is ready - {0}'.format(sysid)
  return True


def hook_check(c, hook, hook_pillar, pillars):
  if 'hooks' in hook_pillar:
    if (hook in hook_pillar['hooks']) and ('enable' in hook_pillar['hooks'][hook]) and (hook_pillar['hooks'][hook]['enable'] == True) and ('state' in hook_pillar['hooks'][hook]):
      print '\nexecuting HOOK {0} --> {1}\n'.format(hook_pillar['hooks'][hook]['state'], hook)
      if not (new_exec_orchestration_state(c, pillars, hook_pillar['hooks'][hook]['state'] )):
        print "failed to exec orchestration state!"
        print False
        return False
      print True
  return True


def verify_resize_cluster_id(c, role, clusterid, minion=None):
  '''
  Input:
  C Conductor class instance
  STR valid role
  INT cluster id to query 

  uses salt grain to find all instance with the correct product.group, role and cluster id.
  
  if found, then the upsize or downsize action that invoked this function can proceed.

  return: True|False, cloud.ROLE.id (if found on matching instances), cluster_members (if found on matching instances)
  '''

  cloud_roleid = 0 # default
  cluster_members  = [] # default

  key = '{0}.{1}.cluster.id'.format(c.product.lower(), role)

  # TODO might need to add saltenv grain to all systems so we can also include that grain in this filter
  if not minion:
    minion='G@{0}.{1}.cluster.id:{2} and G@role:{0}.{1}'.format(c.product.lower(), role, clusterid)

  grains = c.client.cmd(minion, 'grains.items', tgt_type="compound")

  used_ids = []
 
  for n,m in grains.iteritems():
    if isinstance(m, dict):
      if key in m and m[key]:
        used_ids.append(int(m[key]))

        #print 'instance name found', n, type(n)
        _cm = c.get_grain_value(minion=n, key='cluster.members')

        if _cm and isinstance(_cm, list):
          for member in _cm:
            cluster_members.append(member)

        ret = c.get_grain_value(minion=n, key='cloud.{0}.cluster.id'.format(role))

        if ret:
          cloud_roleid = int(ret)

    if len(cluster_members) > 0 and cloud_roleid > 0:
        break

  if clusterid in used_ids:
    return True, cloud_roleid, cluster_members

  return False, cloud_roleid, cluster_members

def get_up_minions():
  '''
  return List of minions that are managed by this master and UP
  '''
  managed_up_minions = []
  exec_cmd = 'salt-run manage.up'
  print 'get salt up minions...'
  output = []
  try:    
    mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    print 'failed exec: {0}\n{1}'.format(exec_cmd, e)
  output, errout = mycmd.communicate()
  if output:
    managed_up_minions = output.strip().replace('\n', ',').replace('- ', '').split(',')

  return managed_up_minions


def get_down_minions():
  '''
  return List of minions that are managed by this master and DOWN
  '''
  managed_down_minions = []
  exec_cmd = 'salt-run manage.down'
  print 'get salt down minions...'
  output = []
  try:
    mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    print 'failed exec: {0}\n{1}'.format(exec_cmd, e)
  output, errout = mycmd.communicate()
  if output:
    managed_down_minions = output.strip().replace('\n', ',').replace('- ', '').split(',')

  return managed_down_minions

def get_minions_status():
  '''
  TODO: need to parse this output and return dict of list
  {"up": [], "down": []}
  '''
  exec_cmd = 'salt-run manage.status'
  print 'get salt minions status...'
  output = []
  try:
    mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    print 'failed exec: {0}\n{1}'.format(exec_cmd, e)
  output, errout = mycmd.communicate()

  print type(output)
  print output
  
  return None
