devops.activemq:
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
        group: devops
  root-volume-tags:
    owner: paulbruno
    purpose: salt dev root vol tag testing
    Contact: paul bruno
    Team: devops
  persist-volumes: False
  volume-info:
    MQdata:
      device: /dev/xvdf
      size: 40
      type: gp2
      tags:
        description: activeMQ data
        Contact: paul bruno
        Team: devops
    MQlogs:
      device: /dev/xvdg
      size: 20
      type: gp2
      tags:
        description: activeMQ logs
        owner: paul bruno
        Contact: paul bruno
        Team: devops
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
  basename: XX.REGION.ENV
  nodes: 1
  size: t2.small
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: devops

devops.dummy:
  force-delay-state: True
  root-volume-tags:
    owner: paul bruno 
  persist-volumes: False
  role: devops.dummy
  additional-grains:
    product.group: devops
    test-grain: foobar
  basename: XX.REGION.ENV
  nodes: 1
  size: t2.small
  tags:
    owner: paulbruno
    purpose: salt testing of roles
    Contact: paul bruno
    Team: devops

devops.test-composite:
  force-delay-state: True
  root-volume-tags:
    owner: paul bruno 
  persist-volumes: False
  role: devops.test-composite
  composite.role: ['devops.activemq', 'devops.dummy']
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
  basename: XX.REGION.ENV
  nodes: 1
  size: t2.small
  tags:
    owner: paulbruno
    purpose: salt testing of composite roles
    Contact: paul bruno
    Team: devops

devops.zookeeper:
  force-delay-state: True
  block-volume:
    - device-name: /dev/sda1
      volume-size: 20
      volume-type: gp2 
      tag:
        owner: paul bruno
  root-volume-tags:
    owner: paulbruno
    purpose: devops zookeeper root vol tag testing
    Contact: not me
    Team: dice
  role: devops.zookeeper
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
        Team: devops
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
        Team: devops
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
        Team: devops
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
            Team: devops
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
            Team: devops
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
            Team: devops
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: devops

devops.zookeeper-alt:
  force-delay-state: True
  startup-override: ['devops.zookeeper']
  role: devops.zookeeper-alt
  role.base: devops.zookeeper
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
        Team: devops
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
        Team: devops
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
        Team: devops
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
    Team: devops

