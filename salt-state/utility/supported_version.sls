# TESTING ONLY
{% set product = salt['pillar.get']('product', None) %} 
{% set pillarpath = salt['pillar.get']('pillarpath', None) %}
{% set version = salt['pillar.get']('version', None) %}
{% set supportedversions = salt['pillar.get'](pillarpath + ':' + product + ':supported-versions', {}) %}
{% if not version in supportedversions %}
exception_version_not_supported_for_{{product}}:
  module.run:
    - name: test.false
{% endif %}  
