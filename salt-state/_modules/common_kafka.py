'''
** not used currently

'''

from salt.exceptions import CommandExecutionError
import os, sys, time
import salt


def _get_client_pillar(name):

  if not name:
    return None

  return __salt__['pillar.get'](name, None)


def set_zookeeper_host(target=None, role=None, pillarenv=None):
  '''
  *** NOT USED AT THIS POINT. NEEDS TO BE UPDATED TO SUPPORT role.base FOR EXTENDED PRODUCT GROUP ROLES.
  THIS IS CALLED FROM A TEST ORCH STATE, BUT THE GRAINS ARE BEING SET USING NEW DISCOVERY PILLAR MODEL

  need to set zookeeper.host grain in this function.
  This is called BEFORE startup state runs which will use the grain
  to update the local kafka config as needed.

  first check if grain exists, if so, return
  if not, look in pillar for group.role:kafka:zookeeper-host value.
  if found, use it. if not found, query salt mine (not implemented yet!)
  if nothing in the mine, return False
  '''  
  
  if not target or not role or not pillarenv:
    return False, "missing one of target, role, pillarenv parameters. All are required"

  zoo_host = __salt__['grains.get']('zookeeper.host', None)

  if zoo_host and len(zoo_host) > 1:
    return True, "grain already exists"

  zoo_host = __salt__['pillar.get']('{0}.role:kafka:zookeeper-host'.format(role.split('.')[1]), None)

  if zoo_host and len(zoo_host) > 1:
    if ":" not in zoo_host:
      ret = __salt__['grains.set']('zookeeper.host', '{0}:2181'.format(zoo_host))
    else:
      ret = __salt__['grains.set']('zookeeper.host', zoo_host)

    verify = __salt__['grains.get']('zookeeper.host', None)

    if verify:
      return True, "grain created and set to {0}".format(zoo_host)
    else:
      return False, "failed to create grain using pillar {0}".format(zoo_host)
  
  # IF WE ARE HERE, WE NEED TO QUERY THE SALT SYSTEM FOR ZOOKEEPER ROLE
  return False, "salt mine not implemented yet"



