# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cpid - cloud provision id
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', None) %}
{% set cpid = salt['pillar.get']('cpid', None) %}

{% if not minion_target == None and not role_target == None %}
{{role_target}}  pre provision orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test pre provision group orchestrate state, nodes {{minion_target}} {{role_target}}

{{role_target}} pre provision orchestration state hook:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: 'saltmaster'
    - tgt_type: glob
    - sls: 
      - common.test.ping
    - pillar: {
        target-minion: {{target}}
      }   
{% endif %}

