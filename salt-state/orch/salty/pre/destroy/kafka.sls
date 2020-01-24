# REQUIRED PARAMETERS:
# target-minion - should be a valid minion name glob, could be in the compound form as well. example: 'server1 or server2 or server3'
# target-role - valid pillar role, used for logging etc...
# OPTIONAL PARAMETERS:
# base-role - if using extended product group roles

{% set minion_target = salt['pillar.get']('target-minion', None) %}
{% set role_target = salt['pillar.get']('target-role', None) %}
{% set cluster_id = salt['pillar.get']('cluster-id', None) %}

{% if not minion_target == None and not role_target == None %}

# PERFORM SOME ACTION ON INSTANCE BEFORE THEY ARE TERMINATED
{{role_target}} stop cluster nodes:
  {% set target = "'L@" + minion_target + " and ( G@role:" + role_target + " or G@composite.role:*" + role_target + "* )'" %}
  salt.state:
    - tgt: {{ target }}
    - tgt_type: compound
    - sls: 
      - common.apache.kafka.stop
    - pillar: {
        target-minion: {{target}}
      }
# cleanup zookeeper stuff here, need to know the zookeeper though
# saltmaster has to do the remote exec to zookeeper to remove old node data, but saltmaster doesn't have the grains like the dependent clusters
{% endif %}
