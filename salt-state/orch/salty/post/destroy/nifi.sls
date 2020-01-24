# REQUIRED PARAMETERS:
# the minion and role could be used for logging etc... since the actual machines are terminated when this is execution.
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role, used for logging etc...
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', None) %}
{% set base_role = salt['pillar.get']('base-role', None) %}

{% if not minion_target == None and not role_target == None %}

{{role_target}} salty post destroy orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test post terminate group orchestrate state, nodes {{minion_target}} {{role_target}}

{{role_target}} salty post destroy  orchestration state hook:
  salt.state:
    - tgt: 'saltmaster'
    - tgt_type: glob
    - sls: 
      - common.test.ping
    - pillar: {
        target-minion: {{minion_target}}
      }   
# example calling product group role state, but needs to execute on master since instance is terminated
{{role_target}} salty post destroy orchestration role state hook from master:
  salt.state:
    - tgt: 'saltmaster'
    - tgt_type: glob
    - sls: 
      - salty.nifi.post_destroy_orch_test
    - pillar: {
        target-minion: {{minion_target}}
      }   

{% endif %}
