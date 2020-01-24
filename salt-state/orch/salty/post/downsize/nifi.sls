# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cluster-id - must be GROUP.ROLE.cluster.id
# pillarenv - since these run on master, this is needed
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set clusterid = salt['pillar.get']('cluster-id', None) %}
{% set role_target = salt['pillar.get']('target-role', 'salty.zookeeper') %}
{% set base_role = salt['pillar.get']('base-role', None) %}
{% set pillarenv = salt['pillar.get']('pillarenv', None) %}

# TRY DYNAMIC IMPORT
{% import_yaml role_target|replace(".", "/") + "/defaults.yaml" as defaults %}

{% if not minion_target == None and not role_target == None and not clusterid == None and not pillarenv == None %}

{{role_target}} salty post downsize orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test post downsize orchestrate state, nodes {{minion_target}} {{role_target}}

{% endif %}
