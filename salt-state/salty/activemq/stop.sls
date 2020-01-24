{% import_yaml "salty/activemq/defaults.yaml" as defaults %}

{% set svc = defaults.activemq['service-name'] %}
execute stop for salty {{ svc }}: 
  module.run:
    - name: state.sls
    - mods: common.stop
    - kwargs: {
          pillar: {
            role: {{ svc }},
            bootstart: True
          }   
      }   
{% set service_installed = salt['service.available']('consul-client') %}

{% if service_installed == True %}
 
stop consul-client for salty {{ svc }}:
  service.dead:
    - names:
      - consul-client
  
{% endif %}
 

