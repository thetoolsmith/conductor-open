# EXAMPLE STATE THAT COULD BE USED TO INVOKE A SERVICE COMMAND USING SALT SYNTAX
# salt '*' devops.activemq.start
# this state calls out to the generic service state and handle the pillar arguments

{% import_yaml "devops/activemq/defaults.yaml" as defaults %}
{% set svc = defaults.activemq['service-name'] %}
execute start for devops {{ svc }}: 
  module.run:
    - name: state.sls
    - mods: common.start
    - kwargs: {
          pillar: {
            service: {{ svc }}, 
            bootstart: True
          }   
      }   
{% set service_installed = salt['service.available']('consul-client') %}
{% if service_installed == True %}
start consul-client for devops {{ svc }}: 
  service.running:
    - names:
      - consul-client
{% endif %}


