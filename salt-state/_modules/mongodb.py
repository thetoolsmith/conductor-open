'''

**** neeeds to be refactored to be more generic....





mongodb salt module for performing automation or integration
'''

from salt.exceptions import CommandExecutionError
import os, sys, time
import salt
import collections
import stat
import simplejson as json
import subprocess

def _get_cluster_grain():

  error_message = []

  this_cluster = []

  this_cluster = __salt__['grains.get']('mongodb.cluster', []) 

  if not this_cluster or not isinstance(this_cluster, list):
    error_message.append('missing mongodb.cluster in grain, or not list type')
    error_message.append('what happened?')

  if len(this_cluster) % 2 == 0:
    error_message.append('Invalid mongo cluster. Member count must be odd number. You have {0}.'.format(len(this_cluster)))

  return this_cluster, error_message

def _get_cluster_hosts_grain():

  '''
  return a list object of dict objects
  each dict object has list type as value
  '''
  error_message = []

  this_cluster = []

  this_cluster = __salt__['grains.get']('mongodb.cluster.hosts', []) 

  if not this_cluster or not isinstance(this_cluster, list):
    error_message.append('missing mongodb.cluster.hosts in grain, or not list type')
    error_message.append('what happened?')

  if len(this_cluster) % 2 == 0:
    error_message.append('Invalid mongo cluster. Member count must be odd number. You have {0}.'.format(len(this_cluster)))

  return this_cluster, error_message
  
def _get_players(cluster):

  error_message = []

  _primary = None
  _arbiter = None
  _secondaries = [] #could be more than one at some point

  for member in cluster:
    if isinstance(member, dict):

      if 'arbiter' in member.items()[0][1]:
        _arbiter = member.items()[0][0]

      elif 'primary' in member.items()[0][1]:
        _primary = member.items()[0][0]

      else:
        _secondaries.append(member.items()[0][0])

    else:
      error_message.append('Failed to determine mongodb cluster roles, {0} is not dict type'.format(member))

  if not _primary:
    error_message.append('Failed to find mongodb cluster primary in {0}.'.format(cluster))

  if not _arbiter:
    error_message.append('Failed to find mongodb cluster arbiter in {0}.'.format(cluster))

  return _primary, _arbiter, _secondaries, error_message

def _get_internalrole_hosts(cluster):

  error_message = []

  _primary = None
  _arbiter = None
  _secondaries = [] #could be more than one at some point

  for role in cluster:
  
    if isinstance(role, dict):
      for r,ip in role.items():
        if 'arbiter' == r:
          _arbiter = ''.join(ip)
        elif 'primary' == r:
          _primary = ''.join(ip)
        elif 'secondary' == r:
          _secondaries.append(''.join(ip))
        else:
          None
    else:
      error_message.append('Failed to determine mongodb cluster hosts, {0} is not list type'.format(role))

  if not _primary:
    error_message.append('Failed to find mongodb cluster primary in {0}.'.format(cluster))

  if not _arbiter:
    error_message.append('Failed to find mongodb cluster arbiter in {0}.'.format(cluster))

  return _primary, _arbiter, _secondaries, error_message


def create_xx_mongodb_init(path=None):
  '''
  generate mongodb init script to be executed on the primary per cluster only.

  RETURN: True | False, message
  '''
  if not path:
    return False, "missing path parameter"

  neid = __salt__['grains.get']('ne_id', None)

  if not neid:
    return False, "missing ne_id grain"

  if int(neid) < 10:
    ne_name = 'ne0{0}'.format(neid)
  else:
    ne_name = 'ne{0}'.format(neid)

  pillar_path = 'ne.config:ne.mongodb:port'

  port = __salt__['pillar.get'](pillar_path, None)

  if not port:
    return False, 'missing mongodb port pillar.'


  # FIRST TRY TO GET THE mongodb.cluster.hosts grain
  this_cluster, errors = _get_cluster_hosts_grain()

 
  if not errors:
    # ITERATE OVER CLUSTER LIST TO FIND THE PRIMARY AND ARBITER
    _primary, _arbiter, _secondaries, errors = _get_internalrole_hosts(this_cluster)

    #return True, 'debugging {0}\n{1}\n{2}'.format(_primary, _arbiter, _secondaries)

  else:
    # THEN TRY TO GET mongodb.cluster grain if hosts grain not found
    this_cluster, errors = _get_cluster_grain()
    if errors:
      return False, errors

    # ITERATE OVER CLUSTER LIST TO FIND THE PRIMARY AND ARBITER
    _primary, _arbiter, _secondaries, errors = _get_players(this_cluster)

    if errors:
      return False, errors

  scriptname = 'initreplica.js'

  with open('{0}/{1}'.format(path, scriptname), 'w') as f:
    f.write('use admin\n\n')
    f.write('var cfg = {0} _id: \'{1}\',\n'.format('{',ne_name) )

    f.write('  members: [\n')

    # new priority logic as of 08/29.2016
    highest_priority = int(len(_secondaries)) + 1 #1 for primary, arbiter doesn't have priority
    f.write('    {0} _id: 0, host: \'{1}:{2}\', priority: {3}{4},\n'.format('{',_primary, port, highest_priority, '}'))
    _idctr = 1
    for n in _secondaries:
      highest_priority-=1
      f.write('    {0} _id: {1}, host: \'{2}:{3}\', priority: {4}{5},\n'.format('{',_idctr, n , port, highest_priority, '}'))
      _idctr+=1
    f.write('    {0} _id: {1}, host: \'{2}:{3}\', arbiterOnly: true{4}\n'.format('{',_idctr, _arbiter, port,'}'))

    f.write('  ]\n')
    f.write('{0};\n\n'.format('}'))
    f.write('var error = rs.initiate(cfg);\n')
    f.write('printjson(error)\n')
    f.write('quit\n')

  # MAKE THE FILE EXECUTABLE FOR ALL
  newfile = '{0}/{1}'.format(path, scriptname)
 
  st = os.stat(newfile)
  os.chmod(newfile, st.st_mode | 0111)

  # IF WE ONLY WANT TO MAKE EXECUTABLE FOR USER | GROUP | WORLD, USE ONE OF THESE
  # os.chmod(newfile, st.st_mode | stat.S_IXUSR)
  # os.chmod(newfile, st.st_mode | stat.S_IXGRP)
  # os.chmod(newfile, st.st_mode | stat.S_IXOTH)

  return True, 'created primary initialization script {0}/{1}'.format(path, scriptname) 

def reconfig_ne_mongodb_init(path=None):
  '''
  same as create_ne_mongodb_init() but sets all non-arbiter nodes to priority 1
  RETURN: True | False, message
  '''
  if not path:
    return False, "missing path parameter"

  neid = __salt__['grains.get']('ne_id', None)

  if not neid:
    return False, "missing ne_id grain"

  if int(neid) < 10:
    ne_name = 'ne0{0}'.format(neid)
  else:
    ne_name = 'ne{0}'.format(neid)

  pillar_path = 'ne.config:ne.mongodb:port'

  port = __salt__['pillar.get'](pillar_path, None)

  if not port:
    return False, 'missing mongodb port pillar.'

  this_cluster, errors = _get_cluster_hosts_grain()

  if not errors:
    _primary, _arbiter, _secondaries, errors = _get_internalrole_hosts(this_cluster)

  else:
    this_cluster, errors = _get_cluster_grain()
    if errors:
      return False, errors

    _primary, _arbiter, _secondaries, errors = _get_players(this_cluster)

    if errors:
      return False, errors

  scriptname = 'reconfig_replica.js'

  with open('{0}/{1}'.format(path, scriptname), 'w') as f:
    f.write('use admin\n\n')
    f.write('var cfg = {0} _id: \'{1}\',\n'.format('{',ne_name) )
    f.write('  members: [\n')
    f.write('    {0} _id: 0, host: \'{1}:{2}\', priority: 1{3},\n'.format('{',_primary, port, '}'))
    _idctr = 1
    for n in _secondaries:
      f.write('    {0} _id: {1}, host: \'{2}:{3}\', priority: 1{4},\n'.format('{',_idctr, n , port,'}'))
      _idctr+=1
    f.write('    {0} _id: {1}, host: \'{2}:{3}\', arbiterOnly: true{4}\n'.format('{',_idctr, _arbiter, port,'}'))
    f.write('  ]\n')
    f.write('{0};\n\n'.format('}'))
    f.write('var error = rs.reconfig(cfg);\n')
    f.write('printjson(error)\n')
    f.write('quit\n')

  newfile = '{0}/{1}'.format(path, scriptname)
 
  st = os.stat(newfile)
  os.chmod(newfile, st.st_mode | 0111)

  return True, 'reconfigured replica script {0}/{1}'.format(path, scriptname) 


def _exec_command(thecmd=None):
    
    error_message = []

    if (thecmd == None):
        return False, []
    try:
        mycmd = subprocess.Popen(thecmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception as e:
      error_message.append('Failed to execute {0}\nerror:{1}'.format(thecmd, e))

      return False, error_message

    output, errout = mycmd.communicate()

    #mongodb cloudmanager returns http 401 Unauthorized every time, but provides the info requested. Bug??
    # not sure, but we cannot properly evaluate the return because of this.
    #if errout:
    #  error_message.append('failed:\n{0}\n{1}'.format(errout, output))
    #  return False, error_message

    return True, output

def remove_mms_host():
  '''
  inputs: None
  return:
    False on fail
  '''

  host = __salt__['grains.get']('localhost', None)

  if not host:
    return False, "missing localhost grain"

  port = __salt__['pillar.get']('ne.config:ne.mongodb:port', None)

  if not port:
    return False, 'missing mongodb port pillar.'

  user = __salt__['pillar.get']('ne.config:ne.mongodb:munin:auth_user', None)

  if not user:
    return False, 'missing munin auth_user pillar.'

  token = __salt__['pillar.get']('ne.config:ne.mongodb:munin:user_token', None)

  if not token:
    return False, 'missing munin user_token pillar.'

  group = __salt__['pillar.get']('ne.config:ne.mongodb:munin:group_token', None)

  if not group:
    return False, 'missing munin group_token pillar.'

  # FIRST GET HOST ID FROM CLOUDMANAGER
  mycmd = 'curl -u {0}:{1} --digest -i https://cloud.mongodb.com/api/public/v1.0/groups/{2}/hosts/byName/{3}'.format( \
          user, token, group, host)

  result, output = _exec_command(mycmd)

  #if not result:
    # output is list when result is False, so safe to return to salt
    # to convert dict to list in any event
    # covertedtolist = [ [k,v] for k, v in output.items() ]
    #return False, output

  if not output:
    return False, 'Failed to get json return from cloud.mongodb.com'

  # MAKE SURE WE HAVE JSON, CONVERT TO DICT AND GET ID
  jsonstring = '{0}{1}'.format('{', output.split('{', 1)[1])

  jsonblock = None
  try:
    jsonblock = json.loads(jsonstring)
  except Exception as e:
    return False, 'output to json FAILED!:\n{0}\n'.format(jsonstring)

  try:
    results_dict = dict(jsonblock)
  except Exception as e:
    return False, 'Failed to convert data to dict, might be invalid json\n{0}\n'.format(e)

  if not 'id' in results_dict:
    return False, 'command:\n{0}\nreturned:\n{1}\n(host id is not in the result set?)\n'.format(mycmd, results_dict)

  hostid = results_dict['id']

  # NOW DELETE THE HOST BY ID
  mycmd = 'curl -u {0}:{1} --digest -i -X DELETE https://cloud.mongodb.com/api/public/v1.0/groups/{2}/hosts/{3}'.format( \
          user, token, group, hostid)

  result, output = _exec_command(mycmd)

  if not result:
    return False, '{0}\nreturned:\n{1}\n'.format(mycmd, output)

  return True, 'Successfully removed {0} from monitoring'.format(host)


