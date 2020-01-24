# ###################################################
# LIQUIBASE INSTALL STATE
# INSTALLS LIQUIBASE CORE AND PRERQUISITE PACKAGES
# ###################################################

{% from "common/map.jinja" import common with context %}

{% set product = 'liquibase-core' %}
{% set role = salt['pillar.get']('role', None) %} 
{% if role == None %}
  {% set role = product %}
{% endif %}
{% set version = salt['pillar.get']('version', common.liquibase_core['product-version']) %}
{% if version == None %}
exception_no_version_{{product}}:
  module.run:
    - name: test.exception
    - message: version not found in defaults or pillar for {{product}}
{% endif %}

{% if common.liquibase_core.srcpath == None %}
exception_null_srcpath_{{product}}:
  module.run:
    - name: test.exception
    - message: default srcpath not found in defaults for {{product}}
{% endif %}

{% set supportedversions = salt['pillar.get']('global:' + product + ':supported-versions', {}) %}

{% for k,v in supportedversions.iteritems() %}
  {% if version == k %}
    # TODO: need to check the md5 hash value as well
    {% set thepackage = v['package'] %}
    {% set version_dir = '/opt/' + product + '/' + version %}
    {% set uri = 'https://' + common.artifactory.user + ':' + common.artifactory.token + '@' + common.artifactory.host + common.liquibase_core.srcpath + version + '/' + thepackage %}
# PREREQUISITES GO HERE
# PULL FROM ARTIFACTORY
fetch {{product}}:
  cmd.run:
    - name: |
        mkdir -p /opt/{{product}}/{{ version }}
        curl {{ uri }} -o /opt/{{product}}/{{ version }}/{{ thepackage }}
        cd /opt/{{product}}/{{ version }}
        unzip {{thepackage}}
    - unless:
      - test -d /opt/{{product}}/{{ version }}

  {% endif %}
{% endfor %}

