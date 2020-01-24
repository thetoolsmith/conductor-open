# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cpid - cloud provision id
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', 'devops.zookeeper') %}
{% set cpid = salt['pillar.get']('cpid', None) %}

{% if not minion_target == None and not role_target == None %}
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}

debug check orch targets:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo targets {{target}}


{{role_target}} post startup orchestration:
  salt.function:
    - name: cmd.run
    - tgt: {{ target }}
    - tgt_type: compound
    - arg:
      - service zookeeper status
{% endif %}
