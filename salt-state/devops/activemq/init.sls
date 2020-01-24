{% import_yaml "devops/activemq/defaults.yaml" as defaults %}

{% set role = 'devops.activemq' %}
{% set version = salt['pillar.get']('version', defaults.activemq['product-version']) %}

{% if version in salt['pillar.get']('global:apache:' + product + ':supported-versions', {}) %}

include:
  - common.base

call common state for {{ role }}: 
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

mount volumes for {{role}}:
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
