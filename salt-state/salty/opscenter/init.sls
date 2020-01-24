# ROLE STATE
{% import_yaml "salty/opscenter/defaults.yaml" as defaults %}
{% set role = salt['pillar.get']('role', salt['grains.get']('role', 'salty.opscenter')) %}
{% set product = role.split('.')[1] %}
{% set version = salt['pillar.get']('version', defaults.opscenter['version']) %}
{% if version in salt['pillar.get']('global:datastax:opscenter:supported-versions', {}) %}

# CHECKS GROUP ROLE PILLAR FIRST, THEN DEFAULTS TO CONFIG.COMMON PILLAR, OR FALSE
{% set enable_alertlogic = salt['pillar.get']('salty.role:enable-alertlogic', salt['pillar.get']('config.common:alertlogic:enabled', False)) %}
{% set enable_sumologic = salt['pillar.get']('salty.role:enable-sumologic', salt['pillar.get']('config.common:sumologic:enabled', False)) %}
{% set enable_datadog = salt['pillar.get']('salty.role:enable-datadog', salt['pillar.get']('config.common:datadog:enabled', False)) %}

include:
  - common.base
{% if not enable_datadog == False %}
  - common.datadog
{% endif %}
{% if not enable_sumologic == False %}
  - common.sumologic
{% endif %}
{% if not enable_alertlogic == False %}
  - common.alertlogic
{% endif %}

call common state for {{ role }}: 
  module.run:
    - name: state.sls
    - mods: common.datastax.opscenter
    - kwargs: {
          pillar: {
{% if not version == None %}
            version: {{ version }},
{% endif %}
            product: opscenter
          }   
      }   
    - require:
      - sls: common.base

mount volumes for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }
      }

  # CONFIGURE DATADOG IF ENABLED
  {% if not enable_datadog == False %}
configure datadog on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.datadog.set-environment
    - kwargs: {
          pillar: {
            user: {{defaults.opscenter['user']}}
          }
      }
  {% endif %}

  # CONFIGURE SUMOLOGIC IF ENABLED
  {% if not enable_sumologic == False %}
configure sumologic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.sumologic.base-config
    - kwargs: {
          pillar: {
            service: {{product}}
          }
      }
  # INIT SUMOLOGIC COLLECTOR
initialize sumologic collector on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.sumologic.init-collector
  {% endif %}

  # START ALERT LOGIC IF ENABLED
  {% if not enable_alertlogic == False %}
start alertlogic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: service.restart
    - m_name: al-agent

status alertlogic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: service.status
    - m_name: al-agent
  {% endif %}

# DEPLOY SECURITY STUFF.... TBD

# START OPSCENTER SERVICE WILL BE INSTALLED NOT STARTED, SO NEED TO START IF DESIRED

{% else %}
# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
