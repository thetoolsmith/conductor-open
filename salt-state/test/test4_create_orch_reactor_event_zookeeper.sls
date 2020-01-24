# MINION SIDE TEST EVENT TRIGGER STATE
# FIRST LINE DENOTES THE event tag
orch/common/runner_reactor_test4:
  event.send:
    - data:
        role: {{grains['role']}}
        target-minion: {{grains['zookeeper.hostname']|join(',')}}
        zoohost: {{grains['zookeeper.host'][0]}}
        znode: "TEST_4_ORCH_REACTOR /TEST_4_ORCH_REACTOR/data"
