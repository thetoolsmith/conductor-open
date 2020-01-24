# ####################################################################
# THIS STATE IS APPLIED WHEN YOU NEED TO RECREATE
# THE CONFIG.JSON ON CONSUL-SERVER NODES
# ####################################################################

{% set role = 'devops.consul-server' %}
{% set service_installed = salt['service.available']('consul-server') %}

{% if service_installed == True %}

  {% set iscomposite = salt['grains.get']('composite.role', None) %}

  {% if (grains['role']|lower == role) or
        ((not iscomposite == None) and (role in grains['composite.role']) ) %}

    {% set consulconfig_path = salt['pillar.get']('devops.role:consul-server:config-location', None) %}

    {% if not consulconfig_path == None %}

update.config stop consul-server service:
  service.dead:
    - names:
      - consul-server

re-generate local {{role}} config:
  module.run:
    - name: common_consul.create_devops_server_config
    - config: {{ consulconfig_path }}
    - env: {{ env }}

update.config startup {{role}} service:
  service.running:
    - names:
      - consul-server

    {% endif %}
  {% endif %}
{% endif %}
