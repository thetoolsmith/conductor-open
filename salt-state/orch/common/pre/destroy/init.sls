# #############################################################################################################
# THIS ORCHESTRATE STATE IS FOR COMMON FUNCTIONALITY WHEN ANY MINIONS ARE DESTROYED REGARDLESS OF PRODUCT GROUP
# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. 
# example: 'server1 or server2 or server3'
# #############################################################################################################

{% set minion_target = salt['pillar.get']('target-minion', None) %}

{% if not minion_target == None %}

pre destroy common orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test pre destroy common orchestrate state, nodes {{minion_target}}

pre destroy common orchestration state hook:
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

