# *** THIS WON'T WORK
# AS IS THE CASE WITH REGULAR NON ORCHESTRATE STATES, YOU CANNOT PERFROM ALL THESE NEEDED TASKS
# WITHIN ONE STATE RUN DUE TO THE COMPILE AND RENDERING PROCESS
# NEED TO CREATE A TEST salt runner. Maybe a new conductor module ... conduct.test 
# need to run the test states directly 3 separate post conductor commands from a jenkins job or something.
# cannot do setup, veryfy and teardown in one state run even within a conductor run. all tested attempts failed with connection refused on verify step.

# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role
# cpid - cloud provision id
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% import_yaml "salty/nifi/defaults.yaml" as defaults %}

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', 'salty.nifi') %}
{% set base_role = salt['pillar.get']('base-role', None) %}

{% set cpid = salt['pillar.get']('cpid', None) %}

{% if not minion_target == None and not role_target == None %}
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}

post.startup test.setup {{role_target}} orchestration state hook:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls: 
      - common.apache.nifi.test.setup
    - pillar: {
        dest-path: {{defaults.nifi['dest-path']}}/nifi/{{defaults.nifi['product-version']}}
      }

post.startup test.verify-web {{role_target}} orchestration state hook:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls: 
      - common.apache.nifi.test.verify-web
    - pillar: {
        dest-path: {{defaults.nifi['dest-path']}}/nifi/{{defaults.nifi['product-version']}}
      }

post.startup test.teardown {{role_target}} orchestration state hook:
  {% set target = "'" + minion_target + "'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: list
    - sls: 
      - common.apache.nifi.test.teardown
    - pillar: {
        dest-path: {{defaults.nifi['dest-path']}}/nifi/{{defaults.nifi['product-version']}}
      }

{% endif %}
