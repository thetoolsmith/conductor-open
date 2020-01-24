from salt.exceptions import CommandExecutionError
import os, sys
import salt

def test_module_echo(config=None):
  return 'passed. {0}'.format(config)

def echo_saltenv(config=None):
 
  values = []
  for i in __opts__:
    values.append(i)

  return 'env= \n{0}'.format(__opts__['state_top_saltenv'])

