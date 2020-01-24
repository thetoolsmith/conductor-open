# TEST ORCH STATE CALLED FROM TEST REACTOR
#
# ORCHESTRATE STATE TO CREATE ZNODE ON ZOOKEEPER
# EXECUTES COMMON PRODUCT STATE
# PILLARS
# target-minion - zookeeper hostname comma separated list or single
# znode - znode string ... don't include the preceeding / 
# role - optional, consuming role

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set znode = salt['pillar.get']('znode', None) %}
{% set role = salt['pillar.get']('role', None) %}

{% if not minion_target == None and not znode == None %}
  {% set target = "'L@" + minion_target + " and ( G@role:*zookeeper* or G@composite.role:*zookeeper* )'" %}

orch create zookeeper znode for {{role}}:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls:
      - common.apache.zookeeper.create-znode
    - pillar: {
  {% if not role == None %}
        role: {{ role }},
  {% endif %}
        znode: {{ znode }}
      }
{% endif %}

