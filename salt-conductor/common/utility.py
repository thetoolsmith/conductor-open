'''
Conductor utility class
'''

import os, sys, traceback, inspect
from sets import Set
from datetime import datetime, timedelta
import time
import argparse
import ast
import simplejson as json
import yaml
import collections

class Logger(object):
  '''
  Logger utility class
  
  Input:
    shell True|False (default) - optionally output to the console. Set in class initialize or by logger.shell=True thereafter

  Usage: From python module 

  import conductor.utility as util

  logger = util.Logger()

  logger.out('something horrible happened', logger.state.error) - specifiy log state
  
  logger.logout('fooobarrrr') - uses default log state
  '''

  def __init__(self, shell=False):

    calling_module = inspect.stack()[1][1]
    line_of_code = inspect.stack()[1][2]
    module_func = inspect.stack()[1][3]

    class state (object):
      info = 'info: '
      warning = 'warning: '
      error = 'error: '

    self.state = state()
    self.modulename = calling_module.split('/')[len(calling_module.split('/')) - 1]
    self.outlog =  '{0}.log'.format(self.modulename.split('.')[0])
    self.logdir = '/srv/runners/logs/conductor'
    self.shell = shell

    try: 
      if not os.path.isdir(self.logdir):
        os.makedirs(self.logdir, 0755 )
    except Exception as e:
      raise RuntimeError('Failed to create {0}\n{1}'.format(self.logdir, e))

    with open('{0}/{1}'.format(self.logdir, self.outlog), 'a') as f:
      f.write('{0} {1}{2}\n'.format(str(datetime.now()), state.info, 'start logging {0}'.format(self.modulename)))

  def log(self, data, logtype=None):
    if not logtype:
      logtype = Logger().state.info

    with open('{0}/{1}'.format(self.logdir, self.outlog), 'a') as f:
      f.write('{0} {1}{2}\n'.format(str(datetime.now()), logtype, data))
      if self.shell:
        calling_func = inspect.stack()[1][3]
        print '{0} <caller - {1}>'.format(data, calling_func)

      return

def verify_caller(caller):

  if caller != inspect.stack()[2][3]:
    return False

  return True

def trace_wrapper(func):
  ''' 
  Wraps timing around input function

  INPUT:

    function

  RETURN:

    function (time delta, function return)

  '''
  def wrapper(*arg, **kw):
    t1 = time.time()
    res = func(*arg, **kw)
    t2 = time.time()

    return (t2 - t1), res 

  return wrapper

@trace_wrapper
def trace(func, *args, **kwargs):

  ''' 
  Tracing function to time wrap function calls.

  Uses decorator trace_wrapper()

  INPUTS:

    FUNCTION func - valid function
 
    LIST args - list or function inputs

    DICT - keyword arg list
 
  RETURN:

    function (timedelta, object)

  '''
  return func(*args, **kwargs)

def print_pretty_dict(obj):
  '''
  Print formatted columns of key value pairs

  INPUT:

    DICT dictionary of key value pairs

  RETURN:

    None

  '''
  maxk, maxv, pad = 0, 0, 2

  try:
    for k,v in obj.items():
      maxk = max(maxk, len(k)) #always a str
      maxv = max(maxv, len(str(v))) #not always a str

    for k,v in obj.items():
      #print "%-*s %*s" % (maxk, k, maxv, v)   #one to print it
      print k.ljust(maxk+pad, ' '), str(v).ljust(maxv+pad, ' ') #another way
  except Exception as e:
    raise RuntimeError('{0}\n{1}'.format(e, type(e)))

  return

def pillar_to_json(data, salt_opts):
  '''
  format pillar data (or any json string) as formatted json 
  input: valid salt pillar tree, or structrured json string

  return : formatted json String block
  '''
  try:
    if 'output_indent' not in salt_opts:
      return json.dumps(data, default=repr, indent=4)

    indent = salt_opts.get('output_indent')
    sort_keys = False

    if indent is None:
      indent = None

    elif indent == 'pretty':
      indent = 4
      sort_keys = True

    elif isinstance(indent, int):
      if indent >= 0:
        indent = indent
      else:
        indent = None

    return json.dumps(data, default=repr, indent=indent, sort_keys=sort_keys)

  except TypeError:
    Logger().log('An error occurred while outputting JSON', Logger().state.erro)
  # Return valid JSON for unserializable objects
  return json.dumps({})

# CONVERTS FROM UNICODE
def convert_from_unicode(data):
  if isinstance(data, basestring):
      return str(data)
  elif isinstance(data, collections.Mapping):
      return dict(map(convert_from_unicode, data.iteritems()))
  elif isinstance(data, collections.Iterable):
      return type(data)(map(convert_from_unicode, data))
  else:
      return data


