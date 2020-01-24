# MINION SIDE TEST EVENT TRIGGER STATE
# EXPECTED SALT-MASTER REACTOR CONFIG
# reactor:
#   - 'local/salty.nifi/zookeeper/create-znode_test1'
#     - salt://reactor/local/common/zookeeper/test1_create-znode.sls?saltenv=test
local/salty.nifi/zookeeper/create-znode_test1:
  event.send:
    - data:
        role: "salty.nifi"
        target-minion: {{grains['zookeeper.hostname']|join(',')}}
        zoohost: {{grains['zookeeper.host'][0]}}
        znode: "TEST_1_LOCAL_REACTOR /TEST_1_LOCAL_REACTOR/data"
