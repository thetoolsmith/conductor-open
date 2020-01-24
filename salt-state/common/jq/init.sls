{% import_yaml "common/jq/defaults.yaml" as defaults %}

{% set version = salt['pillar.get']('version', defaults.jq['product-version']) %}
{% if version == None %}
exception_no_version_{{defaults.jq['product-name']}}:
  module.run:
    - name: test.exception
    - message: version not found in defaults or pillar
{% endif %}

include:
  - common.base

common jq: 
  pkg.installed:
    - name: jq
    - version: {{ version }}
    - require:
      - sls: common.base

