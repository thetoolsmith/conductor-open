# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role (if the role is extended product group role, need to use the role.base for import_yaml and grain check below
# cluster-id - must be GROUP.ROLE.cluster.id
# pillarenv - need this since orch states run on master
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set clusterid = salt['pillar.get']('cluster-id', None) %}
{% set role_target = salt['pillar.get']('target-role', 'UNKNOWN') %}
{% set base_role = salt['pillar.get']('base-role', None) %}
{% set pillarenv = salt['pillar.get']('pillarenv', None) %}

{% set _loadrole = role_target %}
{% if not base_role == None %}
  {% set _loadrole = base_role %}
{% endif %}

# TRY DYNAMIC IMPORT
{% import_yaml _loadrole|replace(".", "/") + "/defaults.yaml" as defaults %}

{% if not minion_target == None and not role_target == None and not clusterid == None and not pillarenv == None %}

{{role_target}} post upsize orchestration:
  {% set target = "'( G@role:" + role_target + " or G@composite.role:*" + role_target + "* ) and ( G@" + role_target + ".cluster.id:" + clusterid|string + " )'" %}

  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - pillarenv: {{pillarenv}}
    - sls: common.apache.zookeeper.create-config
    - pillar: {
{% if 'user' in defaults.zookeeper %}
        user: defaults.zookeeper['user'],
{% endif %}
{% if 'group' in defaults.zookeeper %}
        group: defaults.zookeeper['group'],
{% endif %}
{% if 'dest-path' in defaults.zookeeper %}
        dest-path: {{ defaults.zookeeper['dest-path'] }}, 
{% endif %}
{% if 'zoofile' in defaults.zookeeper %}
        zoofile: '{{ defaults.zookeeper["zoofile"] }}',
{% endif %}
        product: "zookeeper"
      }

{{role_target}} post upsize orchestrate restart service:
  salt.function:
    - name: cmd.run
    - tgt: {{ target }}
    - arg:
      - service zookeeper stop
      - service zookeeper start

{{role_target}} post upsize orchestrate check service:
  salt.function:
    - name: cmd.run
    - tgt: {{ target }}
    - arg:
      - service zookeeper status

{% endif %}
