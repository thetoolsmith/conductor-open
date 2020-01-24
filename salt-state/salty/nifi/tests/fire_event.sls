{% from "salty/map.jinja" import pgroup with context %}

test fire event {{grains['role']}} create-znode:
  {% set znode = 'nifi' + grains[grains['role'] + '.cluster.id']|string %}
  module.run:
    - name: state.sls
    - mods: common.apache.zookeeper.event.create-znode
    - kwargs: {
          pillar: {
            znode: {{znode}} {{znode}}/data,
            zoo-bin: {{pgroup.zookeeper['dest-path']}}/zookeeper/bin/zkCli.sh
          }   
      }
