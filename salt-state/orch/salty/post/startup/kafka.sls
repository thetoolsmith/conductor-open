# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cpid - cloud provision id
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% import_yaml "salty/kafka/defaults.yaml" as defaults %}

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', 'salty.kafka') %}
{% set base_role = salt['pillar.get']('base-role', None) %}

{% set cpid = salt['pillar.get']('cpid', None) %}

{% if not minion_target == None and not role_target == None %}
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}

post startup {{role_target}} orchestration state hook:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls: 
      - common.apache.kafka.create-test-topic
    - pillar: {
  {% if 'dest-path' in defaults.kafka %}
        dest-path: {{ defaults.kafka['dest-path'] }}, 
  {% endif %}
        target-role: {{role_target}}
      }   
{% endif %}
