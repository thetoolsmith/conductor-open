# ppre startup state group wide orchestration state. gets run when a new instance is brought online
# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# product-group - should be the product group as set in grains on new minions
# cpid - cloud provision id

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set group = salt['pillar.get']('product-group', None) %}
{% set cpid = salt['pillar.get']('cpid', None) %}

{% if not minion_target == None and not group == None%}

pre startup {{group}} orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test pre startup group orchestrate state, nodes {{minion_target}}

pre startup {{group}} orchestration state hook:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls: 
      - common.test.ping
    - pillar: {
        target-minion: {{target}}
      }
{% endif %}



