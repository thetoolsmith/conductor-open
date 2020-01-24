'''
User interface for Conductor 
'''
from __future__ import absolute_import

import os, sys 
sys.path.insert(0,'../../..')

from common import aws
from common.utility import Logger
import inspect

logger = Logger(shell=True)


def group(f, **kwargs):
  '''
  call functions in group module

  required:
    f - module function to invoke
    region - aws region us-west-2a for example
    pillarenv=xxx 

  other valid options can be passed in:
    saltenv=xxxx

  CLI: salt-run conduct.group create group=polaris role=all pillarenv=dev region=us-east-1b 
  CLI: salt-run conduct.group create group=metras role=core count=1 pillarenv=dev region=us-east-1b
  CLI: salt-run conduct.group create group=metras role=processor-manager count=3 pillarenv=dev region=us-east-1b
  CLI: salt-run conduct.group destroy group=metras node=processor pillarenv=dev region=us-east-1b
  CLI: salt-run conduct.group destroy group=devops role=devops.cassandra pillarenv=dev region=us-east-1b
  ''' 
  from modules import group as group

  kwargs['__opts__'] = __opts__
  if not 'region' in kwargs and not 'help' in kwargs:
    logger.log('aws region is required', logger.state.error)
    return {}
    
  return getattr(group, '{0}'.format(f))(**kwargs)


def call_me_from_state(message='foo', **kwargs):
  print 'Testing {0} via conduct !!!!!'.format(message)

  return True

def cloud(f, **kwargs):
  '''
  call functions in cloud module

  required:
    f - module function to invoke
    region - aws region us-west-2a for example
    pillarenv=xxx 

  CLI: salt-run conduct.cloud create base pillarenv=dev region=us-east-1b
  ''' 
  from modules import cloud as cloud

  kwargs['__opts__'] = __opts__
  if not 'region' in kwargs:
    logger.log('aws region is required', logger.state.error)
    return {}
   
  return getattr(cloud, '{0}'.format(f))(**kwargs)


def help():
  '''
  import all supported Conductor submodules
  '''
  import inspect
  from modules import group
  from modules import cloud

  all_funcs = inspect.getmembers(sys.modules[__name__], inspect.isfunction)

  print '\nAvailable submodule actions:'

  for f in all_funcs:
    subm = None
    print '\nconduct.{0}'.format(f[0])

    if 'group' == f[0]:
      subm = inspect.getmembers(sys.modules['modules.group'], inspect.isfunction)

    if 'cloud' == f[0]:
      subm = inspect.getmembers(sys.modules['modules.cloud'], inspect.isfunction)

    if subm:
      for sf in subm:
        if not sf[0][0] == '_':
          print '  {0}'.format(sf[0])

  return
