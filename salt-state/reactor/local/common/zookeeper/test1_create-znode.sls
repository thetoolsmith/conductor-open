# REACTOR LOCAL STATE TEST 1 
# TESTING CALL TO STANDARD PRODUCT SALT STATE FROM A REACTOR TRIGGERED LOCAL STATE
# ADVANTAGE IS WE CAN USE THE SAME PRODUCT STATE TO DO THE WORK FROM A REACTOR AS WE DO IN SALT ROLE STATES
{%- do salt.log.error('DATA: %s'|format(data)) %}

test1_common.apache.zookeeper.create-znode:
  local.state.single:
    - tgt: {{data['data']['target-minion']}}
    - tgt_type: list
    - args:
      - fun: module.run
      - name: state.sls
      - mods: common.apache.zookeeper.create-znode
      - kwargs: {
            pillar: {
              znode: {{data['data']['znode']}},
              role: {{data['data']['role']}}
            }   
        }
