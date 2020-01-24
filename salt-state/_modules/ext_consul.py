


'''

*** needs to be refactorted to be generic.....
*** was taken from previous implementation



ext_consul - custom consul salt module for performing client or server side consul
automation or integration
'''

from salt.exceptions import CommandExecutionError
import os, sys, time
import salt

def _get_client_pillar(name):

  if not name:
    return None

  return __salt__['pillar.get'](name, None)


def create_XX_local_config(config=None, env=None):
  '''
  generate local client config for all NE member nodes

  config - path to parent directory to create config.json

  RETURN: True | False, message
  '''
  if not config or not env:
    return False, "missing conig parameter"

  region = __salt__['grains.get']('xx_location', None)

  if not region:
    return False, "missing xx_location grain"

  if 'us-west' in region or 'us-east' in region:
    region = region

  pillar_path = 'consul.common:encrypt-key'

  encrypt_key = __salt__['pillar.get'](pillar_path, None)

  if not encrypt_key:
    return False, 'missing encrypt key pillar, path = {0}'.format(pillar_path)

  consul_servers = []

  # First try using new consul.cluster grains since dns is not supported 3/24/2016
  consul_servers = __salt__['grains.get']('consul.cluster', [])

  if not consul_servers or not isinstance(consul_servers, list):
    # Second attempt, try using pillar config if missing consul.cluster in grain, or not list []
    pillar_path = 'config.common:consul:servers:{0}'.format(region)

    consul_servers = __salt__['pillar.get'](pillar_path, [])

    if not consul_servers or not isinstance(consul_servers, list):
      return False, 'missing consul servers key pillar and grain consul.cluster, or not list [] type. {0}'.format(pillar_path)

  local_cluster = consul_servers[0].split('.')[1]

  with open('{0}/config.json'.format(config), 'w') as f:
    f.write('{\n')
    f.write('  \"server\": false,\n')
    f.write('  \"datacenter\": \"{0}-{1}\",\n'.format(local_cluster, env))
    f.write('  \"data_dir\": \"/tmp/consul-client-data\",\n')
    f.write('  \"encrypt\": \"{0}\",\n'.format(encrypt_key))
    f.write('  \"log_level\": \"INFO\",\n')
    f.write('  \"enable_syslog\": true,\n')
    _holder = None
    for s in consul_servers:
      if _holder:
        _holder = _holder + '\"{0}\"'.format(s) + ','
      else:
        _holder = '\"{0}\"'.format(s) + ','
    _servers = _holder[:-1]
    f.write('  \"start_join\": [{0}]\n'.format(_servers))
    f.write('}\n')

  return True, 'created local consul-client {0}/config.json'.format(config)

def create_rabbitmq_config(config=None, env=None):
  '''
  generate local client rabbitmq config for all rabbitmq role nodes

  config - path to parent directory to create rabbitmq.json

  RETURN: True | False, message
  '''
  if not config or not env:
    return False, "missing conig or env parameter"

  XXid = __salt__['grains.get']('xx_id', None)

  if not XXid:
    return False, "missing ne_id grain"

  xx_name = 'XX' + str(XXid)

  username = _get_client_pillar('config.common:rabbitmq:user-name')
  password = _get_client_pillar('config.common:rabbitmq:password')
  port = _get_client_pillar('config.common:rabbitmq:port')

  if not username or not password or not port:
    return False, 'missing {0}-user, {0}-password and/or {0}-port pillar.'.format('rabbitmq')

  with open('{0}/rabbitmq.json'.format(config), 'w') as f:
    f.write('{\n')
    f.write('  \"service\": {\n')
    f.write('    \"name\": \"{0}-rabbitmq\",\n'.format(ne_name))
    f.write('    \"tags\": [\n')
    f.write('      \"{0}\",\n'.format(ne_name))
    f.write('      \"rabbitmq\"\n')
    f.write('    ],\n')
    f.write('    \"port\": {0},\n'.format(int(port)))
    f.write('    \"check\": {\n')
    f.write('      \"name\": \"status\",\n')
    f.write('      \"http\": \"http://{0}:{1}@localhost:15672/api/aliveness-test/%2F\",\n'.format(username, password))
    f.write('      \"interval\": \"30s\"\n')
    f.write('    }\n')
    f.write('  }\n')
    f.write('}\n')

  return True, 'created local consul-client {0}/rabbitmq.json'.format(config)

def create_mongodb_config(config=None, env=None):
  '''
  generate local client mongodb config for all mongodb role nodes

  config - path to parent directory to create mongodb-state.json

  RETURN: True | False, message
  '''
  if not config or not env:
    return False, "missing conig or env parameter"

  XXid = __salt__['grains.get']('XX_id', None)

  if not XXid:
    return False, "missing XX_id grain"

  xx_name = 'XX' + str(XXid)


  role = __salt__['grains.get']('role', None)
  internalrole = __salt__['grains.get']('internal.role', None)

  username = 'admin'
  password = _get_client_pillar('config.common:mongodb:user:admin')
  port = _get_client_pillar('config.common:mongodb:port')

  if not username or not password or not port:
    return False, 'missing {0}-user, {0}-password and/or {0}-port pillar.'.format('mongodb')

  cfgname = 'mongodb-state'

  with open('{0}/{1}.json'.format(config, cfgname), 'w') as f:
    f.write('{\n')
    f.write('  \"service\": {\n')
    f.write('    \"name\": \"{0}-{1}\",\n'.format(ne_name, cfgname))
    f.write('    \"tags\": [\n')
    f.write('      \"{0}\",\n'.format(ne_name))
    f.write('      \"{0}\"\n'.format(cfgname))
    f.write('    ],\n')
    f.write('    \"port\": {0},\n'.format(int(port)))
    f.write('    \"check\": {\n')
    f.write('      \"name\": \"status\",\n')
    if (role and role == 'ne.mongodb') and (internalrole and internalrole == 'ne.mongodb.arbiter'):
      f.write('      \"script\": \"/etc/XX.d/mongodb-check.sh {0}-{1} localhost:{2}/admin\",\n'.format(XX_name, cfgname, port))
    else:
      f.write('      \"script\": \"/etc/XX.d/mongodb-check.sh {0}-{1} localhost:{2}/admin {3} {4}\",\n'.format(XX_name, cfgname, port, username, password))

    f.write('      \"interval\": \"30s\"\n')
    f.write('    }\n')
    f.write('  }\n')
    f.write('}\n')

  return True, 'created local consul-client {0}/{1}.json'.format(config, cfgname)

def create_server_config(config=None, env=None):
  '''
  generate local server config on consul cluster server

  requires cluster.location and consul.cluster[] salt grain on the node

  config - path to parent directory to create config.json

  RETURN: True | False, message
  '''


  if not config or not env:
    return False, "missing conig parameter"

  region = __salt__['grains.get']('cluster.location', None)

  if not region:
    return False, "missing cluster.location grain"

  if 'us-west' in region or 'us-east' in region:
    region = region

  pillar_path = 'config.common:consul:server:encrypt-key'

  encrypt_key = __salt__['pillar.get'](pillar_path, None)

  if not encrypt_key:
    return False, 'missing encrypt key pillar, path = {0}'.format(pillar_path)

  consul_servers = []

  # First try using new consul.cluster grains since dns is not supported 3/24/2016
  consul_servers = __salt__['grains.get']('consul.cluster', [])

  if not consul_servers or not isinstance(consul_servers, list):
    # Second attempt, try using pillar config if missing consul.cluster in grain, or not list []
    pillar_path = 'config.common:consul:servers:{0}'.format(region)

    consul_servers = __salt__['pillar.get'](pillar_path, [])

    if not consul_servers or not isinstance(consul_servers, list):
      return False, 'missing consul servers key pillar and grain consul.cluster, or not list [] type. {0}'.format(pillar_path)


  wan_members = __salt__['grains.get']('wan.pool.members', [])
  if not wan_members or not isinstance(wan_members, list):
    return False, 'missing consul wan.pool.memebers grain or not list [] type.'

  with open('{0}/config.json'.format(config), 'w') as f:
    f.write('{\n')
    f.write('  \"bootstrap_expect\": 3,\n')
    f.write('  \"server\": true,\n')
    f.write('  \"datacenter\": \"{0}-{1}\",\n'.format(region, env))
    f.write('  \"data_dir\": \"/tmp/consul-server-data\",\n')
    f.write('  \"ui_dir\": \"/usr/share/consul-server/ui\",\n')
    f.write('  \"encrypt\": \"{0}\",\n'.format(encrypt_key))
    f.write('  \"log_level\": \"INFO\",\n')
    f.write('  \"enable_syslog\": true,\n')
    _holder = None
    for s in consul_servers:
      if _holder:
        _holder = _holder + '\"{0}\"'.format(s) + ','
      else:
        _holder = '\"{0}\"'.format(s) + ','
    _servers = _holder[:-1]
    f.write('  \"retry_join\": [{0}],\n'.format(_servers))

    # NOW WAN CONFIG
    _holder = None
    for s in wan_members:
      if _holder:
        _holder = _holder + '\"{0}\"'.format(s) + ','
      else:
        _holder = '\"{0}\"'.format(s) + ','
    _members = _holder[:-1]
    f.write('  \"retry_join_wan\": [{0}]\n'.format(_members))

    f.write('}\n')

  return True, 'created consul-server {0}/config.json'.format(config)

def create_server_watch_config(config=None):
  '''
  generate local server watch config
  '''
  if not config:
    return False, "missing config parameter"

  with open('{0}/watch-config.json'.format(config), 'w') as f:
    f.write('{\n')
    f.write('  \"watches\": [\n')
    f.write('    {\n')
    f.write('      \"type\": \"keyprefix\",\n')
    f.write('      \"prefix\": \"config/\",\n')
    f.write('      \"handler\": \"/etc/xx.d/reconfig-watch.sh 2>&1\"\n')
    f.write('    }\n')
    f.write('  ]\n')
    f.write('}\n')

  return True, 'created consul-server {0}/watch-config.json'.format(config)

