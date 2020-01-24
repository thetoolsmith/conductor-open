# CASSANDRA - COMMON STATE
# OPTIONAL PILLAR PARAMETERS
# version
# java-version
# dest-path
# user
# group
# role

{% from "common/map.jinja" import common with context %}
{% from "common/apache/cassandra/map.jinja" import cassandra with context %}

# OVERWRITES
{% set version = salt['pillar.get']('version', salt['pillar.get']('config.common:apache:cassandra:version', cassandra['product-version'])) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('config.common:apache:cassandra:java-version', cassandra['java-version'])) %}
{% set dest_path = salt['pillar.get']('dest-path', cassandra['dest-path']) %}
{% set user = salt['pillar.get']('user', cassandra['user']) %}
{% set group = salt['pillar.get']('group', cassandra['group']) %}
{% set package = salt['pillar.get']('global:apache:cassandra:supported-versions:' + version + ':package', cassandra['pkg']) %}
{% set product = cassandra['product-name'] %}
{% set role = salt['pillar.get']('role', salt['grains.get']('role', product + '_' + grains['id'])) %}
{% set repo_state = salt['pillar.get']('repo-state', 'common.apache.cassandra.repo') %}

{% set _errors = [] %}
{% if cassandra['product-name'] == None %}
  {% do _errors.append('product-name not found in defaults') %}
{% endif %}
{% if package == None %}
  {% do _errors.append('package not found') %}
{% endif %}
{% if version == None %}
  {% do _errors.append('version not found') %}
{% endif %}
{% if cassandra['srcpath'] == None %}
  {% do _errors.append('srcpath not found') %}
{% endif %}

{% if version in salt['pillar.get']('global:apache:' + product + ':supported-versions', {}) %}

#INSTALL JAVA
install jdk {{java_version}} for {{product}}: 
  module.run:
    - name: state.sls
    - mods: common.oracle.jdk
      {% if not java_version == None %}
    - kwargs: { 
          pillar: {
            version: {{java_version}},
            user: {{user}}
          }   
      }   
      {% endif %}

# YUM REPO
create yum distribution repo for {{product}}:
  module.run:
    - name: state.sls
    - mods: {{repo_state}}

  {% if 'dse' in (version|string) %}
# USING PACKAGE MANAGER NOT ARTIFACTORY
fetch from distro {{package}}:
  cmd.run:
    - name: |
        yum -y update
        yum -y install {{package}}
  {% else %}
    {% set package = salt['pillar.get']('global:apache:' + product + ':supported-versions:' + version + ':package', cassandra['package']) %}
    {% if package == None %}
      {% do _errors.append('package not found') %}
    {% endif %}
# OR FETCH FROM ARTIFACTORY AND CREATE DEST DIR
create {{dest_path}}/{{product}} for {{product}}:
  file.directory:
    - name: {{ dest_path }}/{{product}}
    - makedirs: True
    - user: {{user}}
    - group: {{group}}
    - mode: 755 

fetch {{product}} for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}/cassandra
    - name: |
        curl {{common.artifactory.connector }}{{cassandra['srcpath']}}{{version}}/{{package}} -o {{package}}
        tar zxf {{package}} -C {{dest_path}}/cassandra
        rm -rf {{package}}
        mv {{dest_path}}/cassandra/cassandra* {{dest_path}}/cassandra/{{version}}
    - unless: test -d {{ dest_path }}/cassandra/{{version}}

  {% endif %}

{% endif %}
