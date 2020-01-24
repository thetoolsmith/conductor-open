# ##################################################################################
# LIST THE REQUIRED CONFIGURATION IN THIS ENVIRONMENT (PILLAR BRANCH)
# FOR EACH ROLE OR COMPOSITE ROLE THAT IS AVAILABLE
# MAKE SURE THE PILLAR FILE THAT HOLDS THE ROLE CONFIG DATA IS MAD AVAILABLE
# IN THE PILLAR ROOT TOP.SLS
# make changes 
# ALL COMPOSITE ROLE PROVISIONING CONFIG HERE SHOULD BE PRE-FIXED WITH THE 
# PRODUCT GROUP THAT IS IS ASSOCIATED WITH.
# I.E. devops.utility
# WHERE UTILITY IS THE COMPOSITE ROLE AND IT'S PRODUCT GROUP IS DEVOPS
#
# DUE TO SALT BEHAVIOR, IF ANY ROLE REQUIRES A STATE BE IT DEPLOY STATE, ROLE STATE,
# OR ORCHESTRATION STATE, YOU MUST SPECIFY force-delay-state: True
# THE REASON IS THAT SALT-CLOUD WILL LOCK THE SALT MINION PROCESS WHEN IT APPLIES
# A STARTUP STATE EVEN AFTER THE STARTUP STATE HAS COMPLETED, UNTIL THE TOP PARENT
# PROCESS COMPLETES, WHICH WOULD BE THE CONDUCTOR COMMAND WHEN PROVISIONING.
# ##################################################################################

devops.activemq:
  force-delay-state: True
  root-volume:
    size: 10 
    type: gp2 
  role: devops.activemq
  additional-grains:
    product.group: devops
    test-grain: foobar
    another:
      - one
      - two
      - three
    yetanother:
      bob: employee1
      sue: employee2
  basename: mqXX.REGION.ENV
  nodes: 1
  size: t2.small


devops.cassandra:
  force-delay-state: True
  role: devops.cassandra
  role.base: cassandra
  cluster: True
  cluster-config:
    primary:
      basename: XX.CLUSTERID.REGION.ENV
      nodes: 1
      size: t2.small
      ami-override: 
        us-east-1: ami-4bf3d731
      ebs-optimized: False
      persist-volumes: False
      volume-info:
        logdata:
          device: /dev/sdf
          size: 20
          type: io1 
          iops: 600
          tags: 
            foo: test_vol_tagging
            owner: paul bruno
            Contact: paul bruno
            Team: devops
    seed:
      basename: seedXX.CLUSTERID.REGION.ENV
      nodes: 2
      size: t2.small
      ebs-optimized: False
      persist-volumes: False
      volume-info:
        logdatal:
          device: /dev/sdf
          size: 20
          type: io1 
          iops: 600 
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: devops

devops.nifi:
  force-delay-state: True
  role: devops.nifi
  role.base: nifi
  cluster: True
  nodes: 1
  size: t2.medium
  ami-override: 
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  volume-info:
    datalake:
      device: /dev/xvdf
      size: 30
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: devops
    nifi_provenance_repository:
      device: /dev/xvdg
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: devops
    nifi_content_repository:
      device: /dev/xvdh
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: devops
    nifi_flowfile_repository:
      device: /dev/xvdi
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: devops
    nifi_database_repository:
      device: /dev/xvdj
      size: 10
      type: gp2
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: devops
  cluster-config:
    primary:
      basename: mgr-XX.CLUSTERID.REGION.ENV 
      upstream-config: True
      nodes: 1
    node:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 2

  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: devops
