# REACTOR LOCAL STATE TEST 2 
# TESTING MINION DIRECT FUNCTION CALL FROM A REACTOR TRIGGERED LOCAL STATE
# AVOID NEEDING ANOTHER SALT STATE, BUT MAY DUPLICATE EFFORT IS SALT STATE EXISTS FOR OTHER PURPOSE
test2_common.apache.zookeeper.create-znode:
  local.state.single:
    - tgt: {{data['data']['target-minion']}}
    - tgt_type: list
    - args:
      - fun: cmd.run
      - name: /opt/apache/zookeeper/bin/zkCli.sh -server {{data['data']['zoohost']}} create /{{data['data']['znode']}}
