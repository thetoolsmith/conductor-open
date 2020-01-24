# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cluster-id - must be GROUP.ROLE.cluster.id
# pillarenv - need this since orch states run on master

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set clusterid = salt['pillar.get']('cluster-id', None) %}
{% set role_target = salt['pillar.get']('target-role', 'UNKNONW') %}
{% set pillarenv = salt['pillar.get']('pillarenv', None) %}

# TRY DYNAMIC IMPORT
{% import_yaml role_target|replace(".", "/") + "/defaults.yaml" as defaults %}

{% if not minion_target == None and not role_target == None and not clusterid == None and not pillarenv == None %}

{{role_target}} post downsize orchestration:
  {% set target = "'( G@role:" + role_target + " or G@composite.role:*" + role_target + "* ) and ( G@" + role_target + ".cluster.id:" + clusterid|string + " )'" %}

{{role_target}} post downsize orchestrate test message:
  salt.function:
    - name: cmd.run
    - tgt: {{ target }}
    - arg:
      - echo testing.........
      - echo post downsize for {{role_target}}

{% endif %}
