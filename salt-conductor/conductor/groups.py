'''
Product Groups Class
Every product implemented should be added to Products() class here and have it's own class in this module.

** ALL PRODUCT GROUP CLASSES HERE ARE IDENTICAL. THIS CAN BE REFACTORED TO NOT REQUIRE SEPARATE CLASSES
AND USE EXTERNAL ORGANIZATION SPECIFIC CONFIG FILE LISTING ALL PRODUCT GROUPS WITHIN THAT ORGANIZATION.
THIS WOULD BE THE LAST CHANGE NEEDE TO MAKE CONDUCTOR 100% GENERIC

'''
 
from __future__ import absolute_import

class Products(object):
  CLOUD = 'CLOUD'
  DEVOPS = 'DEVOPS'
  SALTY = 'SALTY' #salt dev testing 
  POLARIS = 'POLARIS'
  DATAMART = 'DATAMART'
  METRAS = 'METRAS'
  NEXUS = 'NEXUS'
  supported = [CLOUD, DEVOPS, METRAS, SALTY]
  cluster_internal_roles = ['primary', 'secondary', 'seed', 'arbiter', 'coordinator']

class Providers(object):
  AWS = 'AWS' 
  ARMOR = 'ARMOR' 
  VMWARE = 'VMWARE'
  supported = [AWS]


'''
*************************************************************************
PRODUCT CLASSES

DEFINE A CLASS FOR ALL SUPPORTED PRODUCTS THAT CONDUCTOR WILL BE MANAGING
CLOUD AND DEVOPS ARE STANDARD
*************************************************************************
'''
class CLOUD(object):

  def __init__(self):
    '''
    '''
    self.tasks = []

  class Conf(object):

    security_groups = {
      'private': {},
      'public': {},
      'management': {}
    }

  class PreConfig(object):
    '''
    properties and such to set before vm cloud create object tasks
    '''
    something = 0

class SALTY(object):

  def __init__(self):
    '''
    '''
    self.nodes = []
    self.instances = []
    self.new_cloud_build = {}
    self.new_cloud_build_xtra = []

  class Conf(object):
    delaystates = [] 
    node_meta = [] #list of dict objects where key=nodename value=metadata
    all_nodes = [] #collection of all nodes of each type being created in this instance 
    default_startup = None
    root_volume_tags = {}

  class PreConfig(object):
    cluster_member_count = 0
    cluster_members = []

  class Prebuild(object):
    '''
    Component data strutcure used by submodules to create cloud conf files 
    needs a constructor because we create many of these in one instance of Conductor.*PRODUCTGROUP*
    '''
    def __init__(self):
      self.component = { "iscluster": False,
                    "cluster-config": {},
                    "nodes": 0,
                    "names": [],
                    "pattern": None,
                    "size": None,
                    "role": None,
                    "roleid": None,
                    "baserole": None,
                    "compositerole": [],
                    "startupoverride": [],
                    "ami_override": None,
                    "internalrole": None,
                    "tags": [],
                    "force_delay_state": False,
                    "ebs_optimize": False,
                    "root_volume_info": {},
                    "volume_info": []}


class DEVOPS(object):

  def __init__(self):
    '''
    '''
    self.nodes = []
    self.instances = []
    self.new_cloud_build = {}
    self.new_cloud_build_xtra = []

  class Conf(object):
    delaystates = [] 
    node_meta = [] #list of dict objects where key=nodename value=metadata
    all_nodes = [] #collection of all nodes of each type being created in this instance 
    default_startup = None
    root_volume_tags = {}

  class PreConfig(object):
    cluster_member_count = 0
    cluster_members = []

  class Prebuild(object):
    '''
    Component data strutcure used by submodules to create cloud conf files 
    needs a constructor because we create many of these in one instance of Conductor.*PRODUCTGROUP*
    '''
    def __init__(self):
      self.component = { "iscluster": False,
                    "cluster-config": {},
                    "nodes": 0,
                    "names": [],
                    "pattern": None,
                    "size": None,
                    "role": None,
                    "roleid": None,
                    "baserole": None,
                    "compositerole": [],
                    "startupoverride": [],
                    "ami_override": None,
                    "internalrole": None,
                    "tags": [],
                    "force_delay_state": False,
                    "ebs_optimize": False,
                    "root_volume_info": {},
                    "volume_info": []}


class METRAS(object):

  def __init__(self):
    '''
    '''
    self.nodes = []
    self.instances = []
    self.new_cloud_build = {}
    self.new_cloud_build_xtra = []

  class Conf(object):
    delaystates = [] 
    node_meta = [] #list of dict objects where key=nodename value=metadata
    all_nodes = [] #collection of all nodes of each type being created in this instance 
    default_startup = None
    root_volume_tags = {}

  class PreConfig(object):
    cluster_member_count = 0
    cluster_members = []

  class Prebuild(object):
    '''
    Component data strutcure used by submodules to create cloud conf files 
    needs a constructor because we create many of these in one instance of Conductor.METRAS
    '''
    def __init__(self):
      self.component = { "iscluster": False,
                    "cluster-config": {},
                    "nodes": 0,
                    "names": [],
                    "pattern": None,
                    "size": None,
                    "role": None,
                    "roleid": None,
                    "baserole": None,
                    "compositerole": [],
                    "startupoverride": [],
                    "ami_override": None,
                    "internalrole": None,
                    "tags": [],
                    "force_delay_state": False,
                    "ebs_optimize": False,
                    "root_volume_info": {},
                    "volume_info": []}

class POLARIS(object):

  def __init__(self):
    '''
    '''
    self.nodes = []
    self.instances = []
    self.new_cloud_build = {}
    self.new_cloud_build_xtra = []

  class Conf(object):
    delaystates = [] 
    node_meta = [] #list of dict objects where key=nodename value=metadata
    all_nodes = [] #collection of all nodes of each type being created in this instance 
    default_startup = None
    root_volume_tags = {}

  class PreConfig(object):
    #for each cluster being created, create a class of this and set cluster member count for use in the cloud map
    cluster_member_count = 0
    cluster_members = []

  class Prebuild(object):
    '''
    Component data strutcure used by submodules to create cloud conf files 
    needs a constructor because we create many of these in one instance of Conductor.polaris
    '''
    def __init__(self):
      self.component = { "iscluster": False,
                    "cluster-config": {},
                    "nodes": 0,
                    "names": [],
                    "pattern": None,
                    "size": None,
                    "role": None,
                    "roleid": None,
                    "baserole": None,
                    "compositerole": [],
                    "startupoverride": [],
                    "ami_override": None,
                    "internalrole": None,
                    "force_delay_state": False,
                    "ebs_optimize": False,
                    "root_volume_info": {},
                    "volume_info": []}

