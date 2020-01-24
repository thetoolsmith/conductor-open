# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cluster-id - must be GROUP.ROLE.cluster.id
# pillarenv - need this since orch states run on master
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set clusterid = salt['pillar.get']('cluster-id', None) %}
{% set role_target = salt['pillar.get']('target-role', 'UNKNONW') %}
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

{{role_target}} post upsize orchestrate test message:
  salt.function:
    - name: cmd.run
    - tgt: {{ target }}
    - arg:
      - echo testing.........
      - echo post upsize for {{role_target}}

{% endif %}
