salty.nifi:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 45
      volume-type: gp2
    - device-name: /dev/sdb
      volume-size: 15
      volume-type: gp2
  root-volume-tags:
    Name: test-custom-name
    owner: paulbruno
    purpose: salty nifi root vol tag testing
    Contact: not me
  role: salty.nifi
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
        Team: salty
  cluster-config:
    primary:
      basename: mgr-XX.CLUSTERID.REGION.ENV 
      upstream-config: True
      nodes: 1
    secondary:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: False
      nodes: 2
      size: t2.small
      ami-override: 
        us-east-1: ami-4bf3d731
      ebs-optimized: False
      persist-volumes: False
      volume-info:
        datalake:
          device: /dev/xvdf
          size: 20
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
    dummy:
      basename: dummy-XX.CLUSTERID.REGION.ENV 
      upstream-config: True
      nodes: 1
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

