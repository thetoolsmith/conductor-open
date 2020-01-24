{% import_yaml "devops/test/defaults.yaml" as defaults %}

{% set role = 'devops.test' %}
{% set version = salt['pillar.get']('version', defaults.test['product-version']) %}

include:
  - common.base
  - .testgpg

call common state for {{ role }}: 
  module.run:
    - name: state.sls
    - mods: common.test
    - kwargs: {
          pillar: {
            role: {{ role }}, 
{% if not version == None %}
            version: {{ version }}, 
{% endif %}           
{% if defaults.test['other-config'] %}
            other-config: {{ defaults.test['other-config'] }}, 
{% endif %}           

          }   
      }   
    - require:
      - sls: common.base
