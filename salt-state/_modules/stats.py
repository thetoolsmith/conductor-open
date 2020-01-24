from salt.exceptions import CommandExecutionError
import salt
import os
import sys
import random
import time
import subprocess

def show_memory(fpath=None, env=None):
  '''
  RETURN: True | False, message
  '''

  if not fpath or not env:
    return False, "missing fpath or env (pillarenv) parameter"

  region = __salt__['grains.get']('node_location', None)
  nodename = __salt__['grains.get']('id', None)
  noderole  = __salt__['grains.get']('role', None)
  iscomposite = __salt__['grains.get']('composite.role', False)
  if iscomposite:
      compositerole = __salt__['grains.get']('composite.role', None)

  if not region:
    return False, "missing node_location grain"

  if 'us-west' in region or 'us-east' in region:
    region = region

  # can lookup pillar for flags to enable/disable specific report items
  enabled = __salt__['pillar.get']('global:stats-reporting:metric:memory', False)
  if not enabled:
    return False, 'memory metric report is not enabled, nothing to do.'

  recipients = __salt__['pillar.get']('global:stats-reporting:recipients', [])

  # dump memory details to variable
  details = []
  try:
    mycmd = subprocess.Popen('dmidecode', shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    return False, 'failed to execute memory dump.\n{0}\n'.format(e)
  details, errout = mycmd.communicate()

  _mail = '{0}/{1}_mail'.format(fpath, str(random.getrandbits(16)))
  with open(_mail, 'w') as f:
    f.write('From: {0}\n'.format(nodename))
    f.write('Subject: memory report\n')
    if details:
      f.write('\n{0}'.format(str(details)))
    else:
      f.write('\nno data generated???')
      
  # send mail now
  _toall = ','.join(recipients)

  exec_cmd = 'sendmail -t \"{0}\" <{1}'.format(_toall, _mail)
  output = []
  try:
    mycmd = subprocess.Popen(exec_cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
  except Exception as e:
    return False, 'failed to send mail.'

  output, errout = mycmd.communicate()

  return True, 'send memory report successfully to {0}'.format(_toall)

