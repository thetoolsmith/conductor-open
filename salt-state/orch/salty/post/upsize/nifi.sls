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

{% set _loadrole = role_target %}
{% if not base_role == None %}
  {% set _loadrole = base_role %}
{% endif %}

# TRY DYNAMIC IMPORT
{% import_yaml _loadrole|replace(".", "/") + "/defaults.yaml" as defaults %}

{% if not minion_target == None and not role_target == None and not clusterid == None and not pillarenv == None %}

{{role_target}} salty testing post upsize orchestration state hook message:
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test pre provision group orchestrate state, nodes {{minion_target}} {{role_target}} this is filter target {{target}}

{{role_target}} post startup orchestration test all:
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: salty.nifi.post_upsize_orch_test

{% endif %}

