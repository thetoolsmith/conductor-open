# *** UNTESTED, NOTHING IS USING THIS

# MINION SIDE ORCH EVENT TRIGGER STATE
# EXPECTED SALT-MASTER REACTOR CONFIG
# reactor:
#   - 'event/orch/common/zookeeper/create-znode'
#     - salt://reactor/orch/common/zookeeper/create-znode.sls?saltenv=test (or whatever saltenv)
# REQUIRES GRAINS TO EXIST
# FIRST LINE DENOTES THE event tag
{% set role = salt['pillar.get']('role', salt['grains.get']('role')) %}
{% set znode = salt['pillar.get']('znode', None) %}
{% if not role == None and not znode == None %}
event/orch/common/zookeeper/create-znode:
  event.send:
    - data:
        role: {{ role }}
        target-minion: {{grains['zookeeper.hostname']|join(',')}}
        zoohost: {{grains['zookeeper.host'][0]}}
        znode: {{ znode }}
        saltenv: {{grains['saltenv']}}
{% else %}
missing configuration event/orch/common/zookeeper/create-znode:
  cmd.run:
    - name: |
        echo role and znode must exist as grain or be specified as pillar
  module.run:
    - name: test.false
{% endif %}
