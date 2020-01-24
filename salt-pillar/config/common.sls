#!yaml|gpg
#
# ####################################################################
# CONFIG THAT IS COMMON ENVIRONMENT WIDE FOR ALL PROVISIONED INSTANCES 
# PRODUCT SPECIFC CONFIGURATION AND SOME OTHER GLOBAL VALUES HERE,
# CAN BE OVERWRITTEN DOWNSTREAM.
# ####################################################################

config.common:

  # PACKAGES TO BE APPLIED TO ALL SERVERS
  packages:
    python:
      version: 2.7
    wget:
      version: 1.2-8
    zip:
      version: 3.0
    salt-minion:
      version: 2017.7.4

  # ALL PRODUCT GROUP UNIQUE ROLE LOOKUP. PRODUCT GROUP IMPLEMENTATIONS OF COMMON ROLES DO NOT NEED TO BE SPECIFIED. 
  # THIS IS ONLY USED IN THE new-instance.sls GENERIC STARTUP STATE

  roles: 
    - cassandra
    - kafka
    - sumologic
    - nifi
    - zookeeper
    - dummy
    - liquibase
    - consul-server
    - consul-client
    - activemq
    - opscenter
    - datalakeapi
  
    # TIP
    # IN OPERATIONALIZED ACTIONS, ALWAYS USE COMPOUND TARGETING AND INCLUDE product.group and role GRAINS 
    # TO ASSURE EXACT TARGETING.

  # SINCE COMPOSITE ROLES ARE NOT PRODUCT BASE ROLES, THE PRODUCT GROUP NAME MUST BE IN THE COMPOSITE ROLE NAME
  roles-composite:
    - devops.utility   # an instance that may have multiple base roles from the list above
    - salty.test-composite
    - devops.test-composite


  # EXAMPLE USED FOR SUPPORT OF CROSS PRODUCT GROUP DEPENDENCIES in (see ORGXinstall.sls). BACK DOOR TO COMPOSITE ROLES.
  # THIS IS NOT GOOD PRACTICE AS IT WOULD INSTALL A ROLE STATE ON AN INSTANCE WITH NO TRACE OF IT IN THE INSTANCES ROLE SALT GRAINS
  role-group-map:
    cloud-coordinator: nexus
    elf: nexus
    platform-core: metras

  # these are environment wide hooks, so anything defined here will be applied to any new instance in the environment regardless of product group or role  
  hooks:
    pre-provision-orchestration: 
      state: ['orch.common.pre.provision']
      enable: False

    pre-startup-orchestration: 
      state: ['orch.common.pre.startup']
      enable: False

    post-startup-orchestration: 
      state: ['orch.common.post.startup']
      enable: True
  
    pre-destroy-orchestration:
      state: ['orch.common.pre.destroy']
      enable: True
  
    post-destroy-orchestration:
      state: ['orch.common.post.destroy']
      enable: True

  # COMMON PRODUCT PER PILLARENV CONFIGURATION 
  alertlogic:
    enabled: False
    agent:
      key: |
        -----BEGIN PGP MESSAGE-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        hIwDndYGtYR5UKMBA/97gT3/0daZBqrNN8LpFBoNxW2SO/E3SeFJW8ddLm+qDD/g
        oCuuR6fIEmRlZJK17OsgyrWRe7I+nTxrZLb7jgP9vo36HzHfsUgBlK0T9SmzDTO3
        MdYKkmp7PUK1Iff0HhDswK0ahcVZZpTIAKR2e5Q1a0Q/BQb1TOL3P3XSNXd9v9Jp
        AS4h4VoxFLsyospJ64ujE11gFDpTLutuV1FbhRzmtbj2Fcb20iS5FcicSfGgOf74
        gjEeRzrYmTs00kGImgYKDXJIRHl7Ak0C0ibeOFua4mAsurN52HdnAO14QL07c1ab
        oPalPl5TKapb
        =qzX5
        -----END PGP MESSAGE-----
      port: 1514
      version: 2.6.0
 
  datadog:
    enabled: False
    agent:
      api-key: |
        -----BEGIN PGP MESSAGE-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        hIwDndYGtYR5UKMBBACvRjI9DFraS4I1QZJFheyYKUdS/UYK0vDkYw3xZ3Wx3paG
        cc8zkQ9wew3EriPIR5uNojl9s4ptlxkiqhgCJ2N00yQfrt52FZk6JPrIDVgd/c/9
        9TeFEIUIvKREnR3ppUONGFQQy/EYdwRIXzLPfw0o/sK57torpEp4L3OfHhhrXNJZ
        AcD+LV0kGlV/jGDjk0dDU+MHgrMC2fCdTsKGEB/pg2P2+3ur4jaBqrZ0gpuavQiA
        HuTxGAI+jBf1+4vzZsTRUzHl8fiRUly/0jzUHRuq/Zgm1qR6PafUY48=
        =dFnx
        -----END PGP MESSAGE-----
  sumologic:
    enabled: False
    access-id: |
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v2.0.22 (GNU/Linux)

      hIwDndYGtYR5UKMBA/99eCtPPbdPt7rTe/zD6sk6Pvd8TxJNDvzu3Iz8xc0+WqI+
      ejuJXzf1m9DXlLEkf+ETY2pRr25SMvUXLv7w32Pwz1lUhPVVCjxiybsKoCNMrJ9d
      eJ1Sa9OguYcBPqPe3ZcoMRUYmNuOVVHkddyfc0Xm5feBbiIZczlrRaCivTilAdJJ
      ATj5l1xkAo+fGNTuqs4wUoW6MW6YkvXJvD7x+3mOrK+RWrHdyp5d9Giy86OD7BjK
      qIRPZZWd8hA0SWf0xilu9JTTARYxs32jRw==
      =PrED
      -----END PGP MESSAGE-----
    access-key: |
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v2.0.22 (GNU/Linux)

      hIwDndYGtYR5UKMBA/9Zm6RA+zH/MGYm3/XnjRw5w7AA6UuyNbH9g+ZMDsEb2lAf
      8S5fkOEidgQdE8UWjbDTn2zWEsGMFP8Ieu2O8Fmgw8KO85vj1yoi0igmsNHsEQDA
      6YDzHgWPJcn3ngYJojc27ggRUzrR4TxgARV+oEjiwC1+n5DFo0LFSQi2/uXXJNJ7
      AZiB1UpviXKTVJ6/j62uqbWhxOWdP9aXE6mFYaBle9ODRr3S2Z0EaSZbNBECltuq
      ttmVOA5BC2LmID0sHxC8wDHrZKshnOeLVYI+mOdlIwf6jFRHqSHeleiiXTKkyz7Q
      ng1ODa9f8cJWe4UBa8Hs9T2iUp/M3eCjlT4z
      =T0lg
      -----END PGP MESSAGE-----

  consul:
    server:
      version: 0.0.1
   
  datastax:
    opscenter:
      version: 6.5.3
      java-version: 1.8.0_181 
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

  apache:
    tomcat:
      version: 8.0.39

    activemq:
      version: 5.15.3

    zookeeper:
      version: 3.5.2-alpha

    kafka:
      version: 2.11-2.0.0

    cassandra:
      version: 3.11.2

    nifi:
      version: 1.5.0

  oracle:
    java:
      version: 1.7.0
    xe:
      version: 11.2.0-1.0
      http_port: 8080
      listener_port: 1521
      enable_db: y
      password: xxx
    client:
      version: 11.2.0.4.0-1
 
  liquibase-core:
    version: 3.5.3
 
  permissions:
    # EXAMPLE CODE ONLY. LIST USER ACCOUNTS TO CREATE ON PROVISIONED VM'S
    users:
      - user1
      - user2
      - ec2-user

    group_membership:

      # ADD ANY SPECIAL GROUP ASSIGMENTS TO USERS
      user1: ['sudo', 'other']
      user2:
        - sudo
        - other
      ec2-user:
        - sudo

  # ENABLE BLOCK VOLUMES NAME, SIZE, TYPE AND TAGS (CAN BE OVERRIDE IN pillar://provisioning/templates)
  # LEAVE OUT THE ROOT DEVICE IF NO NEED TO CHANGE ROOT VOLUME THAT IS AUTO-CREATED BY AWS. IF WE NEED 
  # CHANGE FOR ALL INSTANCE, SET IT HERE, IF NEED TO CHANGE FOR PRODUCT GROUP/ROLE SPECIFIC, SET IT IN 
  # provisioning/templates/xxx.sls
  # BELOW IS ENV WDE DEFAULT
  block-volume:
    - device-name: /dev/sda1
      volume-size: 10
      volume-type: gp2
      tag:
        Team: dice

  # ABOUT ROOT VOLUME. IF BLOCK-COLUME IS NOT SPECIFIED, AWS WILL CREATE A ROOT VOLUME ANYWAY. 
  # TAGS CAN BE SET AT THE ROLE  CONFIGURATION LEVEL, BUT IF NOT SET THERE, THE 'Name' TAG WILL BE SET
  # TO THE INSTANCE HOSTNAME BY DEFAULT SO ALL INSTANCE VOLUMES, INCLUDE THE AUTO-CREATED ROOT VOLUME
  # WILL GET AT LEAST ONE TAG

  # ENVIRONMENT SPECIFIC PERSIST VOLUMES ON INSTANCE TERMINATION
  # SHOULD SET TO FALSE, BUT SET TO TRUE TO TEST DOWNSTREAM CONFIG OF THIS VALUE PER INSTANCE
  persist-volumes: False

  # DEFAULT AMI FOR THE REGION (CAN BE OVERRIDE IN pillar://provisioning/templates)
  ami-image:
    us-east-1: ami-4bf3d731

  # DEFAULT STARTUP/SHUTDOWN STATES FOR ALL COMPONENTS
  # THIS STATE IS APPLIED TO ALL NODES CREATED WITH ROLES IN ANY PRODUCT GROUP THAT DOES NOT HAVE  state: [] configured
  # IF THIS IS NOT DESIRED FOR A ROLE, USE startup-override in the pillar://provisioning/template for the role, or define state: [] in the role config
  default-startup: new-instance
  default-shutdown: 

  # OPTIONAL - ENABLES USERS ON NEW NODES
  enable-users: True
  users-state:

  # OPTIONAL - ENABLES RUNNING ENVIRONMENT WIDE POST DEPLOY ORCHESTRATE STATE FOR ALL INSTAANCES OF ANY PRODUCT GROUP
  run-post-deploy: False
  post-deploy-orchestration: orch.common.post

  # OPTIONAL - ENABLES RUNNING ENVIRONMENT WIDE PRE DESTROY ORCHESTRATE STATE FOR ALL INSTANCES OF ANY PRODUCT GROUP
  run-pre-destroy: False
  pre-destroy-orchestration:

