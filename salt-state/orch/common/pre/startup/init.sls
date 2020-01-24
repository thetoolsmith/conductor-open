# #############################################################################################################
# THIS ORCHESTRATE STATE IS FOR COMMON FUNCTIONALITY WHEN ANY MINIONS ARE CREATED REGARDLESS OF PRODUCT GROUP
# REQUIRED PARAMETERS:
# cpid - cloud provison id
# target-minion - should be a valid minion name glob, could be in the compound form as well. 
# example: 'server1 or server2 or server3'
# #############################################################################################################

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set cpid = salt['pillar.get']('cpid', None) %}

{% if not minion_target == None %}

pre startup common orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test pre startup common orchestrate state, nodes {{minion_target}}

pre startup common orchestration state hook:
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

