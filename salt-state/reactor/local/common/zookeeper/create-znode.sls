# REACTOR LOCAL STATE 
# CREATE ZOOKEEPER ZNODE
{%- do salt.log.info('REACTOR DATA: %s'|format(data)) %}

reactor.local.common.zookeeper.create-znode:
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
              role: {{data['data']['role']}},
              zoo-bin: {{data['data']['zoo-bin']}}
            }   
        }
