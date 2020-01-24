{% import_yaml "devops/activemq/defaults.yaml" as defaults %}
{% set svc = override.activemq['service-name'] %}
execute stop for devops {{ svc }}: 
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
 
stop consul-client for devops {{ svc }}:
  service.dead:
    - names:
      - consul-client
  
{% endif %}
 

