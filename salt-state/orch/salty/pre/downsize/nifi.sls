# EXAMPLE
# 
# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role, used for logging etc...
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', 'salty.nifi') %}

{% if not minion_target == None and not role_target == None %}

# PERFORM SOME ACTION ON INSTANCE BEFORE THEY ARE TERMINATED
{{role_target}} pre downsize orchestration test all:
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: 
      - salty.nifi.pre_downsize_orch_test
    - pillar: {
        target-minion: {{target}}
      } 

# PERFORM SOME ACTION ON SALT MASTER
{{role_target}} salty pre downsize orchestration state hook message:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - echo test pre terminate/destroy group orchestrate state, nodes {{minion_target}} {{role_target}}

{% endif %}
