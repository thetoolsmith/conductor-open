'''
discover.py

Execution module providing service discovery via
use of grains 
product.group
role
id/host
'''

import os, sys
import random
import re
import collections
from common import aws as awsc
import time
import subprocess
import simplejson as json

def service(c, data={}):
  '''
  c - Conductor instance class

  data - criteria for finding services/role/functions
         dict type or key value pairs representing the grains used to discover

         target: single entry dict
                 {"type grain|glob|compound": value}
																	Examples:
                   {"glob": "*foo.bar.*"}
                   {"compound": "G@product.group:devops or G@role:foo and *.dev.*"}
                   {"grain": "G@product.group:other"}

         role: xxxx
         product.group: xxxx
         
  This code will also check composite.role for inclusion of role

  return: True|False, list of dictionaries

          ['{"hostname": xxxx, "ipaddr": x.x.x.x}']

  '''

  role = None
  productgroup = None

  if not data:
    return False, ['missing data parameter']

  if not 'target' in data:
    return False, ['missing target key in data']

  if 'role' in data:
    role = data['role']

  if 'product.group' in data:
    productgroup = data['product.group']

  if not role and not productgroup:
    return False, ['role or product.group or both must be specified']

  for k,v in data['target'].iteritems():
    filter_type = k
    filter_match = v

  err_msg = []

  matches_needed = 0
  matches = 0

  def _execute(cmd):

    output = []  
    try: 
      mycmd = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    except Exception as e:
      print 'Failed to run salt command: {0}\n{1}'.format(cmd, e)
      return False, None
    output, errout = mycmd.communicate()

    print 'salt command: {0}'.format(cmd)
    return True, output

  def _to_dict(j):
    try: 
      ret = dict(json.loads(j))
    except Exception as e:
      print 'Failed to convert data to dict, might be invalid json\n{0}\n'.format(e)
      return None
    return ret


  matched_role = []
  matched_productgroup = []

  if filter_type == 'compound':
    check_role = 'salt -C \'{0}\' grains.item role --out=json --static'.format(filter_match)
    check_productgroup = 'salt -C \'{0}\' grains.item product.group --out=json --static'.format(filter_match)

  elif filter_type == 'grain':
    check_role = 'salt -G \'{0}\' grains.item role --out=json --static'.format(filter_match)
    check_productgroup = 'salt -G \'{0}\' grains.item product.group --out=json --static'.format(filter_match)

  elif filter_type == 'glob':
    check_role = 'salt \'{0}\' grains.item role --out=json --static'.format(filter_match)
    check_productgroup = 'salt \'{0}\' grains.item product.group --out=json --static'.format(filter_match)

  else:
    return False, ['supported target filter not found']

  if role:
    matches_needed+=1
    result, output = _execute(check_role)
    if result:
      ret = _to_dict(output)
      if isinstance(ret, dict):
        for k,v in ret.iteritems():
          if v['ret']['role'] == role:
            matches+=1
            matched_role.append(k)

  if productgroup:
    matches_needed+=1
    result, output = _execute(check_productgroup)
    if result: 
      ret = _to_dict(output)
      if isinstance(ret, dict):
        for k,v in ret.iteritems():
          if v['ret']['product.group'] == productgroup:
            matches+=1
            matched_productgroup.append(k)

  matched_nodes = []

  if matches_needed <= matches:
    if role and productgroup:
      for h in matched_role:
        if h in matched_productgroup:
          matched_nodes.append(h)
    elif role:
      for h in matched_role:
        matched_nodes.append(h)   
    elif productgroup:
      for h in matched_productgroup:
        matched_nodes.append(h)   
    else:
      pass

  return True, matched_nodes



