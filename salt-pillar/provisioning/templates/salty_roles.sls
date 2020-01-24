salty.activemq:
  force-delay-state: True
  spot_config:
    spot_price: 0.10
    tag:
      owner: dice
      contact: paul bruno
      purpose: salt spot request tag testing
  block-volume:
    - device-name: /dev/sda1
      volume-size: 45
      volume-type: gp2
      tag:
        owner: dice
        description: salt dev block device tag testing
        Contact: paul bruno
        Team: dice
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
  basename: XX.REGION.ENV
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
      volume-size: 20
      volume-type: gp2
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: salty nifi root vol tag testing
    Contact: not me
    Team: dice
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
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_provenance_repository:
      device: /dev/xvdg
      size: 20
      type: gp2
      tags:
        description: nifi provenance
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_database_repository:
      device: /dev/xvdh
      size: 20
      type: gp2
      tags:
        description: nifi database
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_flowfile_repository:
      device: /dev/xvdi
      size: 20
      type: gp2
      tags:
        description: nifi flowfile
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    nifi_content_repository:
      device: /dev/xvdj
      size: 20
      type: gp2
      tags:
        description: nifi content
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
      upstream-config: True
      nodes: 2
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
  basename: XX.REGION.ENV
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
    Team: dice
  role: salty.zookeeper
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
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        Contact: paul bruno
        Team: salty
    datalake_logdir:
      device: /dev/xvdh
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        Contact: paul bruno
        Team: salty
    datalake_datadir:
      device: /dev/xvdi
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
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
        datalake:
          device: /dev/xvdf
          description: UUID
          size: 10
          fs-type: ext4
          dump: 0
          pass-num: 2
          mnt-opts:
            - defaults
            - nofail
            - noatime
            - nodiratime
            - barrier=0
            - data=writeback
          type: gp2
          tags:
            description: datalake vol config
            owner: paul bruno
            Contact: paul bruno
            Team: salty
        datalake_logdir:
          device: /dev/xvdh
          description: UUID
          size: 10
          fs-type: ext4
          dump: 0
          pass-num: 2
          mnt-opts:
            - defaults
            - nofail
            - noatime
            - nodiratime
            - barrier=0
            - data=writeback
          type: gp2
          tags:
            description: datalake vol config
            Contact: paul bruno
            Team: salty
        datalake_datadir:
          device: /dev/xvdi
          description: UUID
          size: 10
          fs-type: ext4
          dump: 0
          pass-num: 2
          mnt-opts:
            - defaults
            - nofail
            - noatime
            - nodiratime
            - barrier=0
            - data=writeback
          type: gp2
          tags:
            description: datalake vol config
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
    datalake:
      device: /dev/xvdf
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_logdir:
      device: /dev/xvdh
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        Contact: paul bruno
        Team: salty
    datalake_datadir:
      device: /dev/xvdi
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
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
    Team: dice
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
      - salty.zookeeper.cluster.id.2
    dependency.refresh:
      salty.zookeeper.cluster.id.1: ['common.apache.kafka.update_server_properties']
  volume-info:
    datalake:
      device: /dev/xvdf
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        Contact: paul bruno
        Team: salty
    datalake_logdir_1:
      device: /dev/xvdh
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        Contact: paul bruno
        Team: salty
    datalake_logdir_2:
      device: /dev/xvdi
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
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
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_logdir_1:
      device: /dev/xvdh
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        Contact: paul bruno
        Team: salty
    datalake_logdir_2:
      device: /dev/xvdi
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
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

salty.cassandra:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 20
      volume-type: gp2
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: salty cassandra root vol tag testing
    Contact: not me
    Team: dice
  role: salty.cassandra
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
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_data_1:
      device: /dev/xvdg
      size: 10
      type: gp2
      raid: datalake_data
      tags:
        description: data raid vol 1 config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_data_2:
      device: /dev/xvdh
      size: 10
      type: gp2
      raid: datalake_data
      tags:
        description: data raid vol 2 config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_data_3:
      device: /dev/xvdi
      size: 10
      type: gp2
      raid: datalake_data
      tags:
        description: data raid vol 3 config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_commitlog:
      device: /dev/xvdm
      description: UUID
      size: 10
      type: gp2
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      tags:
        description: datalake commitlog
        owner: paul bruno
        Contact: paul bruno
        Team: salty
  cluster-config:
    primary:
      basename: primary.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 1
    seed:
      basename: XX.CLUSTERID.REGION.ENV
      upstream-config: True
      nodes: 2
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

salty.opscenter:
  force-delay-state: True
  root-volume-tags:
    owner: paulbruno
    purpose: salty opscenter testing
    Team: dice
  role: salty.opscenter
  basename: XX.REGION.ENV
  nodes: 1
  size: t2.medium
  ami-override: 
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  volume-info:
    datalake:
      device: /dev/xvdf
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

salty.datalakeapi:
  force-delay-state: True
  root-volume-tags:
    owner: paulbruno
    purpose: salty datalakeapi testing
    Team: dice
  role: salty.datalakeapi
  basename: XX.REGION.ENV
  nodes: 1
  size: t2.medium
  ami-override:
    us-east-1: ami-4bf3d731
  ebs-optimized: False
  persist-volumes: False
  volume-info:
    datalake:
      device: /dev/xvdf
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake vol config
        owner: paul bruno
        Contact: paul bruno
        Team: salty
    datalake_logdir:
      device: /dev/xvdg
      description: UUID
      size: 10
      fs-type: ext4
      dump: 0
      pass-num: 2
      mnt-opts:
        - defaults
        - nofail
        - noatime
        - nodiratime
        - barrier=0
        - data=writeback
      type: gp2
      tags:
        description: datalake_logdir
        owner: paul bruno
        Contact: paul bruno
        Team: salty
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty

