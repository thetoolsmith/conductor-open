#!yaml|gpg

# ##############################################################################################################
# CONFIGURATION OF TEAM SPECIFIC ROLES. THESE MAY REF STATES THAT CALL THE COMMON ROLE OF THE SAME PRODUCT
# ROLES DO NOT HAVE DEPENDENCIES. STATES HAVE DEPENDENCIES. ROLES CAN BE PUT IN COMPOSITE ROLES WITH OTHER ROLES
# UNLESS THE ROLE IS A CLUSTER. IN WHICH CASE YOU WOULD USE A 'SYSTEM' TO STANDUP MULTIPLE CLUSTERS THAT 
# DEPEND ON EACH OTHER
# ##############################################################################################################

salty.role:

  product-path: /com/orgX/

  enable-alertlogic: True # overriding config.common:alertlogic:enabled for testing

  enable-sumologic: False # overriding config.common:sumologic:enabled for testing

  enable-datadog: True # overriding config.common:datadog:enabled for testing

  enable-dns: False

  javax.net.ssl.keyStorePassword: |
    -----BEGIN PGP MESSAGE-----

    hIwDndYGtYR5UKMBBACZa/wnmiFc5ESiZNUCVZn73uXJombRAZEv0kikLT04EUYN
    FX8XgdOwGKfB2803buPsiGdpmcLwn58Ot0r/bDp2aQ22j4zmGbe2gTNJHYE7ogJy
    kWcc/ZPzrzfdPyTkNV9jH/4o6nzwcxCFCvz4AvpNKgAdzoSmziLjqEcRDGX2NdJK
    AZMYWLFQFDesCCifw6V8eXhvcVRKmilPG5DHcM1Mn3531SdVyAYZ1AXtpwjnIsCf
    2agKpn4hPCVKcR6kCoIPC88LptzOOqxkfO0=
    =sGzg
    -----END PGP MESSAGE-----

  javax.net.ssl.trustStorePassword: |
    -----BEGIN PGP MESSAGE-----

    hIwDndYGtYR5UKMBBACZa/wnmiFc5ESiZNUCVZn73uXJombRAZEv0kikLT04EUYN
    FX8XgdOwGKfB2803buPsiGdpmcLwn58Ot0r/bDp2aQ22j4zmGbe2gTNJHYE7ogJy
    kWcc/ZPzrzfdPyTkNV9jH/4o6nzwcxCFCvz4AvpNKgAdzoSmziLjqEcRDGX2NdJK
    AZMYWLFQFDesCCifw6V8eXhvcVRKmilPG5DHcM1Mn3531SdVyAYZ1AXtpwjnIsCf
    2agKpn4hPCVKcR6kCoIPC88LptzOOqxkfO0=
    =sGzg
    -----END PGP MESSAGE-----

  # product group wide hooks, role based hooks are under the role config, common (env) wide hoos are in common.config
  hooks:
    pre-provision-orchestration: 
      state: ['orch.salty.pre.provision']
      enable: False

    pre-startup-orchestration: 
      state: ['orch.salty.pre.startup']
      enable: True

    post-startup-orchestration: 
      state: ['orch.salty.post.startup']
      enable: True

    pre-destroy-orchestration:
      state: ['orch.salty.pre.destroy']
      enable: True
  
    post-destroy-orchestration:
      state: ['orch.salty.post.destroy']
      enable: True

  all:
    - liquibase
    - nifi
    - cassandra
    - dummy
    - consul-server
    - activemq
    - zookeeper
    - zookeeper-alt
    - kafka
    - kafka-alt
    - opscenter
    - datalakeapi

  # THIS BLOCK IS STRICTLY USED TO TEST PILLAR OVERRIDES THROUGH CONDUCTOR CREATE
  test-overrides:
    setting-one: value1
    setting-two: value2
    test-one:
      - grain: id
        filter:
          role: zookeeper
          salty.zookeeper.cluster.id: 1
    level-two:
      setting-one: value21
      setting-two: value22
      level-three:
        key1: paul
        key2: 10
        folders:
          - /tmp/one
          - /tmp/two
          - /tmp/three


  dummy:
    security-group: public
    state: ['salty.dummy']
    dependencies:
      common.apache.activemq: 5.15.2

  consul-server:
    security-group: public
    state: ['salty.consul-server']
 
  activemq:
    security-group: public
    product-version: 5.15.3
    state: ['salty.activemq']
    hooks:
      pre-provision-orchestration: 
        state: ['orch.salty.pre.provision.activemq']
        enable: True
      pre-startup-orchestration: 
        state: ['orch.salty.pre.startup.activemq']
        enable: True
      pre-destroy-orchestration:
        state: ['orch.salty.pre.destroy.activemq']
        enable: True
  
  liquibase:
    security-group: public
    state: ['salty.liquibase']
    java:
      version: 1.8.0_101

  zookeeper:
    security-group: private
    product-version: zookeeper-3.4.10
    hooks:
      post-startup-orchestration:
        state: ['orch.salty.post.startup.zookeeper']
        enable: True
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.zookeeper']
        enable: True
      post-downsize-orchestration:
        state: ['orch.common.post.downsize.zookeeper']
        enable: True
    elb:
      name: ZOOKEEPER-ELB
    state: ['salty.zookeeper']
    java:
      version: 1.8.0_181

  zookeeper-alt:
    security-group: private
    hooks:
      post-startup-orchestration:
        state: ['orch.salty.post.startup.zookeeper']
        enable: False
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.zookeeper']
        enable: True
      post-downsize-orchestration:
        state: ['orch.common.post.downsize.zookeeper']
        enable: True
    state: ['salty.zookeeper']

  kafka:
    security-group: private
    product-version: confluent-4.0.0
    discovery:
      - grain: ipv4
        filter:
          role: zookeeper
          cluster.member.id: "*"
          salty.zookeeper.cluster.id: 1
        element: 0
        local:
          grain: zookeeper.host
          prefix:
          suffix: ":2181"
          type: list
      - grain: id
        filter:
          role: zookeeper
          salty.zookeeper.cluster.id: 1
        local:
          grain: zookeeper.hostname
          prefix:
          suffix:
          type: list
      - grain: id
        filter:
          salty.zookeeper.cluster.id: 1
        local:
          grain: runtime.dependencies
          type: list
      - grain: selinux
        filter:
          role: zookeeper
          cluster.member.id: "*"
          salty.zookeeper.cluster.id: 1
        key: enabled
        local:
          grain: zookeeper.selinux.enabled
          type: dict

    hooks:
      post-startup-orchestration:
        state: ['orch.salty.post.startup.kafka']
        enable: False
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.kafka']
        enable: True
      post-downsize-orchestration:
        state: ['orch.common.post.downsize.kafka']
        enable: True
    state: ['salty.kafka']
    java:
      version: 1.8.0_181

  kafka-alt:
    security-group: private
    product-version: confluent-4.0.0
    discovery:
      - grain: ipv4
        filter:
          role: zookeeper-alt
          cluster.member.id: 1
        local:
          grain: zookeeper.host
          prefix:
          suffix: ":2181"
          type: string
      - grain: id
        filter:
          role: zookeeper-alt
        local:
          grain: zookeeper.hostname
          prefix:
          suffix:
          type: list
    hooks:
      post-startup-orchestration:
        state: ['orch.salty.post.startup.kafka']
        enable: False
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.kafka']
        enable: True
      post-downsize-orchestration:
        state: ['orch.common.post.downsize.kafka']
        enable: True
    state: ['salty.kafka']
    java:
      version: 1.7.0

  nifi:
    security-group: private
    discovery:
      - grain: ipv4
        filter:
          role: zookeeper
          cluster.member.id: "*"
          salty.zookeeper.cluster.id: 1
        element: 0
        local:
          grain: zookeeper.host
          prefix:
          suffix: ":2181"
          type: list
      - grain: id
        filter:
          role: zookeeper
          salty.zookeeper.cluster.id: 1
        local:
          grain: zookeeper.hostname
          prefix:
          suffix:
          type: list
      # THIS IS FOR TESTING, NOT USING THIS YET
      - grain: id
        filter:
          salty.zookeeper.cluster.id: 1
        local:
          grain: runtime.dependencies
          type: list
    hooks:
      pre-startup-orchestration:
        state:
        enable: False
        grains-pillar: zookeeper.hostname #THIS IS JUST FOR EXAMPLE. WE WOULD NEED TO UPDATE CONDUCTOR TO PASS A GENERIC LIST OF GRAINS VIA PILLAR DEF TO THE ORCH STATE
      post-startup-orchestration:
        state: ['orch.salty.post.startup.nifi']
        enable: True
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.nifi', 'orch.salty.post.upsize.nifi']
        enable: False
      pre-downsize-orchestration:
        state: []
        enable: False
    elb:
      name: TEST-NIFI-ELB
    dependencies:
      common.apache.activemq: 5.15.2
    state: ['salty.nifi', 'common.jq']
    java:
      version: 1.8.0_101

  opscenter:
    version: 6.5.3
    security-group: private
    state: ['salty.opscenter']

  datalakeapi:
    version: 3.0.3-SNAPSHOT
    security-group: private
    state: ['salty.datalakeapi']
    elb:
      name: DATALAKEAPI

  cassandra:
    product-version: dse-6.0.2
    java:
      version: 1.8.0_181 # this overrides the state default
    security-group: private
    # RAID CONFIG IS LOCATED HERE, SO THAT NUMBER OF VOLUMES AND VOLUME DEVICES IS NOT NEEDED.
    # SIMPLY CONFIGURE ANY NUMBER OF VOLUMES AND DEVICES IN provisioning/templates PILLAR TREE
    # AND SET raid: THE_RAID_NAME_DEFINED_HERE. ALL CONFIG OPTIONS ARE THE SAME.
    # THIS DESIGN ALLOWS FOR MULTIPLE RAIDS TO BE CONFIGURED FOR A SINGLE PRODUCT ON THE SAME INSTANCE
    # ALL IN THE PROVISIINGING PROCESS
    raid:
      datalake_data:
        device: /dev/md0
        description: LABEL=datalake_data
        fs-type: ext4
        dump: 0
        pass-num: 2
        level: 0
        mnt-opts:
          - defaults
          - nofail
        mount-dir: /mnt

    dse_user: |
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v2.0.22 (GNU/Linux)

      hIwDndYGtYR5UKMBA/9Jtp3u1ujDzGp+of92NZrtpZRcPwEly0jQ3ckgdFt6DXgy
      qWgZwmnYnJalyIG+hHTlfaTF7xrx07yKQNHR/iIFXDVRxpJeN+2Pj+6HVkIwz2DH
      phnagxFirvfyKkQYeh7RCRxMOc+sACjfRW/9oQ4vCPhwfhLzadaDTwY1psDpTtJM
      AWwCI+pYBSwe1jn1zYzHu8pteTlaY+4XEeSsrM/JTrWRKYokcOw1RC3/RCFv7IgP
      ZxMcQQokwW7t89sUHcD+iLpEf969ob/r9sqJMQ==
      =uwUa
      -----END PGP MESSAGE-----
    dse_password: |
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v2.0.22 (GNU/Linux)

      hIwDndYGtYR5UKMBA/41b55sY/DMxTwY5AitoV9pUv0NJZkX2bdjnzx51VqYq+QN
      3Y5ZXNlY/4sReyKOk+TYt94+wfYKNzEPiytddgXYwUF+r6rUbrvlSwj4lTjBqQHh
      BO5gjKdLL0LfigddDADWv4dJZXxFWaw1obtODkzBBkBFQFzsSiHW6qDtCkrugdJK
      ARxxOViBIDmmkzDymtOP+evrnXFyE5QEpTB7gcsK1hmrlQe+iMnD5bxsy1r3IoIH
      hTc0YOJV31Xul2RzeJTAgEIprNsF7dNdmB0=
      =iCUF
      -----END PGP MESSAGE-----
    encryption_options:
      keystore_password: |
        -----BEGIN PGP MESSAGE-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        hIwDndYGtYR5UKMBBACVjaJ3Ft9tWQk2U8+jMFNuJz1WPkcpEo7z3aMmzyah7csq
        DMZNNwh3pAtCNCKlW/mEcsXKrAHTlktayIfwxX/ev+K0jRlwMOWkcPJZR4o70kuH
        pC3Ohk7xurVUQoalSlaW589jbWeQVhLzxrfT7kdlxBcUqg1skuIGaH6L9mNefNJK
        AbJLFqim7Piv7MrJI7TYJm8Ni21+LeDFV+C9tefWITgGTPYEUpNx9XfQ9gK3MQR0
        i5jq2lkmKyrqPRa/q49Yq/PR1dHwlzsRTaQ=
        =8CJH
        -----END PGP MESSAGE-----
      truststore_password: |
        -----BEGIN PGP MESSAGE-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        hIwDndYGtYR5UKMBBACVjaJ3Ft9tWQk2U8+jMFNuJz1WPkcpEo7z3aMmzyah7csq
        DMZNNwh3pAtCNCKlW/mEcsXKrAHTlktayIfwxX/ev+K0jRlwMOWkcPJZR4o70kuH
        pC3Ohk7xurVUQoalSlaW589jbWeQVhLzxrfT7kdlxBcUqg1skuIGaH6L9mNefNJK
        AbJLFqim7Piv7MrJI7TYJm8Ni21+LeDFV+C9tefWITgGTPYEUpNx9XfQ9gK3MQR0
        i5jq2lkmKyrqPRa/q49Yq/PR1dHwlzsRTaQ=
        =8CJH
        -----END PGP MESSAGE-----

    client_encryption_options:
      keystore_password: |
        -----BEGIN PGP MESSAGE-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        hIwDndYGtYR5UKMBBACVjaJ3Ft9tWQk2U8+jMFNuJz1WPkcpEo7z3aMmzyah7csq
        DMZNNwh3pAtCNCKlW/mEcsXKrAHTlktayIfwxX/ev+K0jRlwMOWkcPJZR4o70kuH
        pC3Ohk7xurVUQoalSlaW589jbWeQVhLzxrfT7kdlxBcUqg1skuIGaH6L9mNefNJK
        AbJLFqim7Piv7MrJI7TYJm8Ni21+LeDFV+C9tefWITgGTPYEUpNx9XfQ9gK3MQR0
        i5jq2lkmKyrqPRa/q49Yq/PR1dHwlzsRTaQ=
        =8CJH
        -----END PGP MESSAGE-----
      truststore_password: |
        -----BEGIN PGP MESSAGE-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        hIwDndYGtYR5UKMBBACVjaJ3Ft9tWQk2U8+jMFNuJz1WPkcpEo7z3aMmzyah7csq
        DMZNNwh3pAtCNCKlW/mEcsXKrAHTlktayIfwxX/ev+K0jRlwMOWkcPJZR4o70kuH
        pC3Ohk7xurVUQoalSlaW589jbWeQVhLzxrfT7kdlxBcUqg1skuIGaH6L9mNefNJK
        AbJLFqim7Piv7MrJI7TYJm8Ni21+LeDFV+C9tefWITgGTPYEUpNx9XfQ9gK3MQR0
        i5jq2lkmKyrqPRa/q49Yq/PR1dHwlzsRTaQ=
        =8CJH
        -----END PGP MESSAGE-----
    discovery:
      - grain: ipv4
        filter:
          role: cassandra
          internal.role: seed
          cpid: CURRENT_CPID
        element: 0
        local:
          grain: cluster.seed_nodes
          type: list
      - grain: id
        filter:
          role: cassandra
          internal.role: seed
          cpid: CURRENT_CPID
        local:
          grain: cluster.seed_nodes.hostname
          type: list
      - grain: ipv4
        filter:
          role: cassandra
          internal.role: seed
          salty.cassandra.cluster.id: CURRENT_CLUSTER
        element: 0
        local:
          grain: cluster.seed_nodes
          type: list
      - grain: id
        filter:
          role: cassandra
          internal.role: seed
          salty.zookeeper.cluster.id: CURRENT_CLUSTER
        local:
          grain: cluster.seed_nodes.hostname
          type: list
    hooks:
      post-startup-orchestration:
        state: []
        enable: False
      post-upsize-orchestration:
        state: []
        enable: False
      pre-downsize-orchestration:
        state: []
        enable: False
    state: ['salty.cassandra']

