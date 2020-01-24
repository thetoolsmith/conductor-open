from __future__ import absolute_import
import os, sys

from conductor import Conductor
from groups import Products
from groups import Providers

def load(the_group):

  if not the_group.upper() in Products.supported:
    raise AttributeError('product not supported')

  print 'product specified = {0}'.format(the_group.upper())

  try:
    if not os.path.isdir('/srv/runners/cloud_runs'):
      os.mkdir('/srv/runners/cloud_runs', 0755 )
  except Exception as e:
    raise RuntimeError('Failed to create {0}'.format('/srv/runners/cloud_runs'))
  try:
    if not os.path.isdir('/srv/runners/state_runs'):
      os.mkdir('/srv/runners/state_runs', 0755 )
  except Exception as e:
   raise RuntimeError('Failed to create {0}'.format('/srv/runners/state_runs'))

  obj = Conductor(provider=Providers.AWS, product=the_group.upper())

  return obj

