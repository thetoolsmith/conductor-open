# *** untested salt master config is configured with this, but nothing is firing the event
# and thus the orch state this is calling is not being used by anything else either.



# ORCH REACTOR STATE FOR EVENT orch/common/zookeeper/create-znode
# ADVANTAGE IS WE CAN USE THE SAME PRODUCT ORCH STATE TO DO THE WORK FROM A REACTOR AS WE DO IN SALT ROLE HOOK STATES
{%- do salt.log.error('DATA: %s'|format(data)) %}

reactor/orch/common/zookeeper/create-znode:
  runner.state.orchestrate:
    - args:
      - mods: orch.common.apache.zookeeper.create-znode
      - saltenv: {{data['data']['saltenv']}}
      - pillar:
          target-minion: {{data['data']['target-minion']}}
          znode: {{data['data']['znode']}}
          role: {{data['data']['role']}}
          zoo-bin: {{data['data']['zoo-bin']}}
