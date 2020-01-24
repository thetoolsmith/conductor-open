# ########################################################
# EXECUTE A PILLAR RESET ON NEW BRANCHES/SALT ENVIRONMENTS
# REQUIRES resets.yaml 
# WILL NULL OUT ANY VALUE DEFINED IN RESETS SCHEMA
# ########################################################
import os, sys
import subprocess
import time
import yaml
import random

data = None

def out_to_file(newdata, top_level_key):
  ''' this function is not used, left temporarily '''
  filename = '__{0}'.format(str(random.getrandbits(32)))
  x = ' '
  with open(filename, 'w') as f:
    f.write('{0}:\n'.format(top_level_key))
    for k,v in newdata.iteritems():
      if isinstance(v, dict):
        f.write('{0}{1}:\n'.format(2*x,k))
        for kk,vv in v.iteritems():
          if isinstance(vv, dict):
            f.write('{0}{1}:\n'.format(4*x,kk))
            for kkk,vvv in vv.iteritems():
              f.write('{0}{1}:\n'.format(6*x,kkk))
          elif isinstance(vv, list):
            f.write('{0}{1}:\n'.format(4*x,kk))
            for i in vv:
              f.write('{0}- {1}\n'.format(6*x,i))
          else:
            f.write('{0}{1}: {2}\n'.format(6*x,kk, vv))
      elif isinstance(v, list):
        f.write('{0}{1}:\n'.format(2*x,k))
        for i in v:
          f.write('{0}- {1}\n'.format(4*x,v))
      else:
        f.write('{0}{1}: {2}\n'.format(2*x,k,v))

  return filename

def process_file(fp):
  content = []
  if not os.path.exists(fp):
    print 'invalid file name'
    return False

  with open(fp, 'r') as stream:
    _content = stream.readlines()
  
  for x in _content:
    content.append(x.rstrip())
  
  return content

def merge_with_preserve(currentdata, resetdata):
  '''
  arg1 - current pillar data from filepath as a list of strings
  arg2 - resetdata list of strings from resets.yaml pertaining to the filepath of arg1

  function will compare both sets of data, replacing all key values pairs defined in arg2
  that it finds in arg1. Any other key values pairs found in arg1 will be preserved
  '''

  if not isinstance(currentdata, list) or not isinstance(resetdata, list):
    return []

  mergedata = []

  resetline_total = len(resetdata)
  resetline_start = 0

  removing_pgp = False
  enter_pgp_block = False
  for a in currentdata:
    ctr = 0
    matched = False
    resetline_ctr = 0

    while resetline_ctr < resetline_total:

      if (resetdata[resetline_ctr].split(':')[0] + ':') == (a.split(':')[0] + ':'):
        matched = True
        if '|' in a:
          enter_pgp_block = True
        resetline_start= resetline_start + 1 # only bump resetdata start if/when we have found the match
        mergedata.append(resetdata[resetline_ctr])
        break
      resetline_ctr = resetline_ctr + 1          

    # SPECIAL CASE WHEN WE HAVE PGP CIPHERTEXT        
    if matched:
      pass
    elif not matched and 'END PGP MESSAGE' in a and enter_pgp_block:
      enter_pgp_block = False
    elif not matched and enter_pgp_block:
      pass 
    else:
      mergedata.append(a)

  return mergedata


def __process_file(fp,reset_obj):
  ''' this function is not used, left temporarily '''
  if not os.path.exists(fp):
    print 'invalid file name'
    return False

  newobject = {}

  data = None
  with open(fp, 'r') as stream:
    try:
      data = yaml.load(stream)
    except yaml.YAMLError as e:
      print 'failed', e

  def walklist(obj1,obj2):
    for i1 in obj1:
      for i2 in obj2:
        if i1 == i2:
          if isinstance(i1, dict):
            obj1 = evaldict(i1,i2)
          elif isinstance(i1, list):
            obj1 = walklist(i1,i2)
          else:
            obj1.append('CHANGE_ME')
        else:
          obj1.append(i1)

    return obj1

  def evaldict(obj1, obj2):
    #d1 = { k : v for k,v in obj1.iteritems() if v}    
    d1 = {}
    updated = []
    copyobj = {}
    for k1,v1 in obj1.iteritems():
      for k2,v2 in obj2.iteritems():
        if k1 == k2:
          if isinstance(v2, dict):
            d1 = evaldict(v1,v2)
          elif isinstance(v2, list):
            d1 = walklist(v1,v2)
          else:
            if not k1 in updated:
              d1[k1] = 'CHANGE_ME'
              updated.append(k1)

    obj1.update(d1)
   
    for k,v in d1.iteritems():
      if isinstance(v, dict):
        copyobj[k] = v

    if copyobj:
      return copyobj

    return obj1

  top_level_key = data.items()[0][0]
   
  newdata = evaldict(data,reset_obj)

  # WRITE TO FILE
  tempfile = out_to_file(newdata, top_level_key)

  print tempfile

  return True


if __name__ == "__main__":

  _resetfile = '{0}/resets.yaml'.format(os.path.dirname(os.path.realpath(sys.argv[0])))
  with open(_resetfile, 'r') as stream:
    try:
      data = yaml.load(stream)
    except yaml.YAMLError as e:
      print 'failed', e

  if not isinstance(data, dict):
    print 'not dealing with a properly converted yaml dict'
    sys.exit(1)


  _resets = yaml.load(yaml.dump(data))

  global resetdata
  resetdata = []

  def _deep(d,indenting):
    global resetdata
    space = ' '
    for x,y in d.iteritems():
      if isinstance(y, dict):
        resetdata.append('{1}{0}:'.format(x,indenting*space))
        _deep(y,indenting+2)
      else:
        resetdata.append('{2}{0}: {1}'.format(x,y,indenting*space))

  indent = 0
  space = ' '

  for k,v in _resets.iteritems():
    #print k       #this is the filepath root element in resets.yaml
    resetdata = [] #reset list after each filepath is processed

    if isinstance(v, dict):
      _deep(v, indent)
    else:
      resetdata.append('{3}{0}: {1}'.format(k,v, indent*space))

    for filepath,resetinfo in data.iteritems():
      if k == filepath:
        print '\nprocess file: {0}'.format(filepath)
        currentdata = process_file(filepath)
        
        mergedata = merge_with_preserve(currentdata, resetdata)

        # open filepath and overwrite it
        with open (filepath, 'w') as f:
          for i in mergedata:
            f.write('{0}\n'.format(i))

        break #always need to assure we break and loop once after we found the correct filepath match

    #break #for testing just first entry
 
  print '\ncompleted!'

