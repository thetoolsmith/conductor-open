# REACTOR ORCH STATE TEST 4
# TESTING DIRECT CALL TO PRODUCT ORCHESTRATE SALT STATE FROM A REACTOR TRIGGERED RUNNER ORCH STATE
# ADVANTAGE IS WE CAN USE THE SAME PRODUCT ORCH STATE TO DO THE WORK FROM A REACTOR AS WE DO IN SALT ROLE HOOK STATES
{%- do salt.log.error('DATA: %s'|format(data)) %}

test orch.common.test.create-znode:
  runner.state.orchestrate:
    - args:
      - mods: orch.common.test.create-znode
      - saltenv: 'test'
      - pillar:
          target-minion: {{data['data']['target-minion']}}
          znode: {{data['data']['znode']}}
          role: {{data['data']['role']}}
          zoo-bin: {{data['data']['zoo-bin']}}
