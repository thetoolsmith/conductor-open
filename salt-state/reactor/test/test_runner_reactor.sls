# REACTOR ORCH STATE TEST 3
# TESTING DIRECT CALL TO PRODUCT ORCHESTRATE SALT STATE FROM A REACTOR TRIGGERED RUNNER ORCH STATE
# ADVANTAGE IS WE CAN USE THE SAME PRODUCT ORCH STATE TO DO THE WORK FROM A REACTOR AS WE DO IN SALT ROLE HOOK STATES
# NEED TO PASS saltenv
{%- do salt.log.error('DATA: %s'|format(data)) %}

test orch.common.test.runner_reactor:
  runner.state.orchestrate:
    - mods: orch.common.test.runner_reactor
    - saltenv: 'test'
