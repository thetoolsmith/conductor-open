{% from "salty/map.jinja" import pgroup with context %}

{% set user = salt['pillar.get']('user', 'root') %}
{% set service = salt['pillar.get']('service', 'unspecified') %}

include:
  - common.datadog
  - common.sumologic
  - common.alertlogic

# CONFIGURE DATADOG IF ENABLED
{% if not pgroup.enable_datadog == False %}
configure datadog on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.datadog.set-environment
    - kwargs: {
          pillar: {
            user: {{user}}
          }
      }
  # TODO enhance this to select a config file from salt source based on service
  {% if service == 'zookeeper' %}
enable dd yaml for {{service}} on {{grains['id']}}:
  cmd.run:
    - name: |
        cp -rf /etc/dd-agent/conf.d/zk.yaml.example /etc/dd-agent/conf.d/zk.yaml
  {% endif %}
{% endif %}

# CONFIGURE SUMOLOGIC IF ENABLED
{% if not pgroup.enable_sumologic == False %}
configure sumologic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.sumologic.base-config
    - kwargs: {
          pillar: {
            service: {{service}}
          }
      }
# INIT SUMOLOGIC COLLECTOR
initialize sumologic collector on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.sumologic.init-collector
{% endif %}

# START ALERT LOGIC IF ENABLED
{% if not pgroup.enable_alertlogic == False %}
start alertlogic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: service.restart
    - m_name: al-agent

status alertlogic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: service.status
    - m_name: al-agent
{% endif %}
