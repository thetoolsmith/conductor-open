{% import_yaml "salty/activemq/defaults.yaml" as defaults %}

{% set role = 'salty.activemq' %}
{% set version = salt['pillar.get']('version', defaults.activemq['product-version']) %}

{% if version in salt['pillar.get']('global:apache:activemq:supported-versions', {}) %}
include:
  - common.base

call_common_state_for_salty: 
  module.run:
    - name: state.sls
    - mods: common.apache.activemq
    - kwargs: {
          pillar: {
            role: {{ role }}, 
{% if not version == None %}
            version: {{ version }}, 
{% endif %}           
          }   
      }   
    - require:
      - sls: common.base

mount_volumes_for_salty:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }   
      }
{% else %}

# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
