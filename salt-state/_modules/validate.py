from salt.exceptions import CommandExecutionError
import salt
import os
import sys
import random
import time
import subprocess
import json

def test_echo():
  return True, "good to go"

def dump_grains(dest=None):
  '''
  dest - filepath and file name
  '''
  if not dest:
    return False, ['missing dest parameter']

  err_msg = []
  info = []
  if not dest:
    err_msg.append('Missing parameters') 
    return False, err_msg

  _grains = __salt__['grains.items']
  info.append('var is type {0}'.format(type(_grains())))

  with open(dest, 'w') as fp:
    formatted = json.dumps(str(_grains()), default=repr, indent=4, sort_keys=True)
    fp.write(formatted)

  return True, info



