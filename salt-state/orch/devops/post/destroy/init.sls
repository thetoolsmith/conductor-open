# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# product-group - should be the product group as set in grains on new minions

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set group = salt['pillar.get']('product-group', None) %}

{% if not minion_target == None and not group == None%}

post destroy {{group}} orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test post destroy group orchestrate state, nodes {{minion_target}}

post destroy {{group}} orchestration state hook:
  salt.state:
    - tgt: 'saltmaster'
    - tgt_type: glob
    - sls: 
      - common.test.ping
    - pillar: {
        target-minion: {{minion_target}}
      }
{% endif %}



