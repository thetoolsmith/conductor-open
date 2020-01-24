# ##############################################################################################################
# CONFIGURATION OF TEAM SPECIFIC ROLES. THESE MAY REF STATES THAT CALL THE COMMON ROLE OF THE SAME PRODUCT
# ROLES DO NOT HAVE DEPENDENCIES. STATES HAVE DEPENDENCIES. ROLES CAN BE PUT IN COMPOSITE ROLES WITH OTHER ROLES
# UNLESS THE ROLE IS A CLUSTER. IN WHICH CASE YOU WOULD USE A 'SYSTEM' TO STANDUP MULTIPLE CLUSTERS THAT 
# DEPEND ON EACH OTHER
# ##############################################################################################################

devops.role:

  product-path: /com/orgX/

  hooks:
    pre-provision-orchestration: 
      state: ['orch.devops.pre.provision']
      enable: True

    pre-startup-orchestration: 
      state: ['orch.devops.pre.startup']
      enable: True

    post-startup-orchestration: 
      state: ['orch.devops.post.startup']
      enable: True

  all:
    - liquibase
    - zookeeper
    - zookeeper-alt
    - dummy
    - activemq

  dummy:
    security-group: public
    state: ['devops.dummy']

  activemq:
    security-group: public
    product-version: 5.15.5
    state: ['devops.activemq']
   
  liquibase:
    security-group: public
    state: ['devops.liquibase']
    java:
      version: 1.8.0_101

  zookeeper:
    security-group: private
    product-version: 3.4.10
    state: ['devops.zookeeper']
    hooks:
      post-startup-orchestration:
        state: ['orch.devops.post.startup.zookeeper']
        enable: True
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.zookeeper']
        enable: True
      post-downsize-orchestration:
        state: ['orch.common.post.downsize.zookeeper']
        enable: True
    java:
      version: 1.8.0_101

  zookeeper-alt:
    security-group: private
    product-version: 3.4.10
    state: ['devops.zookeeper']
    hooks:
      post-startup-orchestration:
        state: ['orch.devops.post.startup.zookeeper']
        enable: True
      post-upsize-orchestration:
        state: ['orch.common.post.upsize.zookeeper']
        enable: True
      post-downsize-orchestration:
        state: ['orch.common.post.downsize.zookeeper']
        enable: True
    java:
      version: 1.8.0_181
