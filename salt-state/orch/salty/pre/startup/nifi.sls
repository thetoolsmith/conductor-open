# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role (roles should have the productgroup.role syntax, so we don't need product group pillar to be passed
# cpid - cloud provision id
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', 'salty.nifi') %}
{% set cpid = salt['pillar.get']('cpid', None) %}
{% set resizing = salt['pillar.get']('resizing', False) %}

{% if not minion_target == None and not role_target == None %}

{{role_target}} pre startup orchestration test all:
  {% set target = "'( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: salty.nifi.pre_orch_test

  {% if resizing == False %}
{{role_target}} pre startup orchestration primary only:
  {% set target = "'G@internal.role:manager and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )  and ( L@" + minion_target + " )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: salty.nifi.pre_orch_test

{{role_target}} pre startup orchestration dummy only:
  {% set target = "'G@internal.role:dummy and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )  and ( L@" + minion_target + " )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: salty.nifi.pre_orch_test
  {% endif %}

{{role_target}} pre startup orchestration secondary only:
  {% set target = "'G@internal.role:secondary and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )  and ( L@" + minion_target + " )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: salty.nifi.pre_orch_test

{% endif %}

