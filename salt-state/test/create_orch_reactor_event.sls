orch/test/zookeeper/create-znode:
  event.send:
    - data:
        role: "salty.nifi"
        target-minion: "salty-zookeeper-01.clid-1.us-east-1a.test.foobar.com,salty-zookeeper-02.clid-1.us-east-1a.test.foobar.com"
        znode: "TEST_ORCH_REACTOR /TEST_ORCH_REACTOR/data"
