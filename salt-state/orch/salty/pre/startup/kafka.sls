# ** not used currently
# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cpid - cloud provision id
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', 'salty.kafka') %}
{% set cpid = salt['pillar.get']('cpid', None) %}
{% set pillarenv = salt['pillar.get']('pillarenv', None) %}

{% if not minion_target == None and not role_target == None %}
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}

pre startup {{role_target}} orchestration hook:
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls: 
      - common_kafka.set_zookeeper_host
    - pillar: {
        target: {{minion_target}},
        role: {{role_target}},
        pillarenv: {{pillarenv}}
      } 
 
{% endif %}
