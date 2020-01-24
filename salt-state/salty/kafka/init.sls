# ROLE STATE
{% from "salty/map.jinja" import pgroup with context %}

{% set role = salt['pillar.get']('role', salt['grains.get']('role', 'salty.kafka')) %}
{% set product = role.split('.')[1] %}
{% set version = salt['pillar.get']('version', pgroup.kafka['product-version']) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('salty.role:' + product + ':java:version', pgroup.kafka['java-version'])) %}
{% set server_properties = {} %}
{% if 'server-properties' in pgroup.kafka %}
  {% set server_properties = pgroup.kafka['server-properties'] %}
{% endif %}

{% set env_vars = {} %}

{% if version in salt['pillar.get']('global:apache:kafka:supported-versions', {}) %}

include:
  - common.base

mount volumes for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }   
      }   

  # CREATE LOCAL APPUSER IF NOT DEFAULT CLOUD USER 
  {% if not salt['pillar.get']('ami-user-map:' + grains['os']) == pgroup.kafka['appuser'] %}
{{role}}_user:
  user.present:
    - name: {{pgroup.kafka['appuser']}}
    - gid: {{pgroup.kafka['appgroup']}}
    - shell: /bin/bash
    - createhome: True
    - require:
      - group: {{role}}_group
{{role}}_group:
  group.present:
    - name: {{pgroup.kafka['appgroup']}}
  {% endif %}

call common state for {{ role }}: 
  module.run:
    - name: state.sls
    - mods: common.apache.kafka
    - kwargs: {
          pillar: {
{% if not version == None %}
            version: {{ version }},
{% endif %}
{% if not java_version == None %}
            java-version: {{ java_version }},
{% endif %}
{% if 'dest-path' in pgroup.kafka %}
            dest-path: {{ pgroup.kafka['dest-path'] }},
{% endif %}
{% if 'appuser' in pgroup.kafka %}
            user: {{ pgroup.kafka['appuser'] }},
{% endif %}
{% if 'appgroup' in pgroup.kafka %}
            group: {{ pgroup.kafka['appgroup'] }},
{% endif %}
{% if not server_properties|length == 0 %}
            server-properties: {{ server_properties }},
{% endif %}
            product: {{product}}
          }   
      }   
    - require:
      - sls: common.base

  # FIRE EVENT TO CREATE ZNODE

  # DEPLOY SVC STATE AND SET ENV
deploy {{role}} service on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.deploy_service
    - kwargs: {
          pillar: {
            svc: kafka
          }   
      }

  # APPLY MONITORING STATES
monitoring for {{role}} on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.monitoring
    - kwargs: {
          pillar: {
    {% if 'appuser' in pgroup.kafka %}
            user: {{pgroup.kafka['appuser']}},
    {% endif %}
            service: kafka
          }   
      }
    {% if 'server-properties' in pgroup.kafka and 'log-dirs' in pgroup.kafka['server-properties'] %}
      {% for d in pgroup.kafka['server-properties']['log-dirs'] %}
{{d}}:
  file.directory:
    - makedirs: True
    - user: {{pgroup.kafka['appuser']}}
    - group: {{pgroup.kafka['appgroup']}}
    - dir_mode: 755
    - file_mode: 744
    - recurse:
      - user
      - group
      - mode
      {% endfor %}
    {% endif %}

{% else %}
# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
