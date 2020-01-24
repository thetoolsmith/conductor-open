# MINION SIDE TEST EVENT TRIGGER STATE
# EXPECTED SALT-MASTER REACTOR CONFIG
# reactor:
#   - 'local/salty.nifi/zookeeper/create-znode_test2'
#     - salt://reactor/local/common/zookeeper/test2_create-znode.sls?saltenv=test
#
# FIRST LINE DENOTES THE event tag
local/salty.nifi/zookeeper/create-znode_test2:
  event.send:
    - data:
        role: "salty.nifi"
        target-minion: {{grains['zookeeper.hostname']|join(',')}}
        zoohost: {{grains['zookeeper.host'][0]}}
        znode: "TEST_2_LOCAL_REACTOR /TEST_2_LOCAL_REACTOR/data"
