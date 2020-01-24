salty.activemq:
  force-delay-state: True
  spot_config:
    spot_price: 0.10
    tag:
      contact: paul bruno
      purpose: salt spot request tag testing
  block-volume:
    - device-name: /dev/sda1
      volume-size: 45
      volume-type: gp2
      tag:
        description: salt dev block device tag testing
        Contact: paul bruno
        group: salty
  root-volume-tags:
    owner: paulbruno
    purpose: salt dev root vol tag testing
    Contact: paul bruno
    Team: salty
  persist-volumes: False
  volume-info:
    MQdata:
      device: /dev/xvdf
      size: 40
      type: gp2
      tags:
        description: activeMQ data
        Contact: paul bruno
        Team: salty
    MQlogs:
      device: /dev/xvdg
      size: 20
      type: gp2
      tags:
        description: activeMQ logs
        owner: paul bruno
        Contact: paul bruno
        Team: salty
  role: salty.activemq
  additional-grains:
    product.group: salty
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
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

salty.nifi:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 45
      volume-type: gp2
    - device-name: /dev/sdb
      volume-size: 15
      volume-type: gp2
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: salty nifi root vol tag testing
    Contact: not me
  role: salty.nifi
  cluster: True
  nodes: 1
  size: t2.medium
  ami-override: 
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  additional-grains:
    zookeeper.connect:
      - salty.zookeeper.cluster.id.1
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
    nifi_provenance_repository:
      device: /dev/xvdg
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_content_repository:
      device: /dev/xvdh
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_flowfile_repository:
      device: /dev/xvdi
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_database_repository:
      device: /dev/xvdj
      size: 10
      type: gp2
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
  cluster-config:
    primary:
      basename: primary.CLUSTERID.REGION.ENV 
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
        nifi_provenance_repository:
          device: /dev/xvdg
          size: 10
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        nifi_content_repository:
          device: /dev/xvdh
          size: 10
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        nifi_flowfile_repository:
          device: /dev/xvdi
          size: 10
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        nifi_database_repository:
          device: /dev/xvdj
          size: 10
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



salty.nifi:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 45
      volume-type: gp2
    - device-name: /dev/sdb
      volume-size: 15
      volume-type: gp2
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: salty nifi root vol tag testing
    Contact: not me
  role: salty.nifi
  cluster: True
  nodes: 1
  size: t2.medium
  ami-override: 
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  additional-grains:
    zookeeper.connect:
      - salty.zookeeper.cluster.id.1
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
    nifi_provenance_repository:
      device: /dev/xvdg
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_content_repository:
      device: /dev/xvdh
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_flowfile_repository:
      device: /dev/xvdi
      size: 10
      type: gp2 
      tags: 
        description: test_upstream_role_config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_database_repository:
      device: /dev/xvdj
      size: 10
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
        nifi_provenance_repository:
          device: /dev/xvdg
          size: 10
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        nifi_content_repository:
          device: /dev/xvdh
          size: 10
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        nifi_flowfile_repository:
          device: /dev/xvdi
          size: 10
          type: gp2 
          tags: 
            description: test_internal_role_config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        nifi_database_repository:
          device: /dev/xvdj
          size: 10
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

salty.dummy:
  force-delay-state: True
  root-volume-tags:
    owner: paul bruno 
  persist-volumes: False
  role: salty.dummy
  additional-grains:
    product.group: salty
    test-grain: foobar
  basename: XX.REGION.ENV
  nodes: 1
  size: t2.small
  tags:
    owner: paulbruno
    purpose: salt testing of roles
    Contact: paul bruno
    Team: salty

salty.test-composite:
  force-delay-state: True
  root-volume-tags:
    owner: paul bruno 
  persist-volumes: False
  role: salty.test-composite
  composite.role: ['salty.activemq', 'salty.dummy']
  additional-grains:
    product.group: salty
    test-grain: foobar
    another:
      - one
      - two
      - three
    yetanother:
      bob: employee1
      sue: employee2
  basename: test-compositeXX.REGION.ENV
  nodes: 1
  size: t2.small
  tags:
    owner: paulbruno
    purpose: salt testing of composite roles
    Contact: paul bruno
    Team: salty

salty.zookeeper:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 20
      volume-type: gp2 
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: salty zookeeper root vol tag testing
    Contact: not me
  role: salty.zookeeper
  cluster: True
  nodes: 1
  size: t2.medium
  ami-override:
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  volume-info:
    data:
      device: /dev/xvdf
      size: 100 
      type: gp2 
      tags:
        description: data vol for zookeeper
        Contact: paul bruno
        Team: salty
  cluster-config:
    primary:
      basename: primary.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 1
    secondary:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: False
      nodes: 2
      size: t2.medium
      ami-override:
        us-east-1: ami-4bf3d731
      ebs-optimized: False
      persist-volumes: False
      volume-info:
        data:
          device: /dev/xvdf
          size: 100 
          type: gp2 
          tags:
            description: data vol for zookeeper
            Contact: paul bruno
            Team: salty
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

salty.zookeeper-alt:
  force-delay-state: True
  startup-override: ['salty.zookeeper']
  role: salty.zookeeper-alt
  role.base: salty.zookeeper
  cluster: True
  nodes: 1
  size: t2.medium
  ami-override:
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  volume-info:
    data:
      device: /dev/xvdf
      size: 30
      type: gp2
      tags:
        description: data vol for zookeeper
        Contact: paul bruno
        Team: salty
  cluster-config:
    primary:
      basename: primary.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 1
    secondary:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 2
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty


salty.kafka:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 20
      volume-type: gp2 
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: salty kafka root vol tag testing
    Contact: not me
  role: salty.kafka
  cluster: True
  nodes: 1
  size: t2.medium
  ami-override:
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  additional-grains:
    zookeeper.connect:
      - salty.zookeeper.cluster.id.1
    dependency.refresh:
      salty.zookeeper.cluster.id.1: ['common.apache.kafka.update_server_properties']
  volume-info:
    datalake:
      device: /dev/xvdf
      size: 100 
      type: gp2 
      tags:
        description: data vol for kafka
        Contact: paul bruno
        Team: salty
  cluster-config:
    primary:
      basename: primary.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 1
    secondary:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 2
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

salty.kafka-alt:
  startup-override: ['salty.kafka']
  force-delay-state: True
  role: salty.kafka-alt
  role.base: salty.kafka
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
        description: data vol for kafka
        Contact: paul bruno
        Team: salty
  cluster-config:
    primary:
      basename: primary.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 1
    secondary:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 2
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty


