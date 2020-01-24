# OPSCENTER - COMMON STATE
# INSTALLS DATASTAX OPSCENTER 
# DYNAMIC PILLAR OPTIONS:
# version
# java-version
# user 
{% from "common/map.jinja" import common with context %}
{% import_yaml "common/datastax/defaults.yaml" as defaults %}
{% set product = 'opscenter' %}
{% set version = salt['pillar.get']('version', defaults.opscenter['version']) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('config.common:datastax:opscenter:java-version', defaults.opscenter['java-version'])) %}
{% set user = salt['pillar.get']('user', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set repo_state = salt['pillar.get']('repo-state', 'common.datastax.repo') %}

{% if version in salt['pillar.get']('global:datastax:opscenter:supported-versions') %}
  {% set package = salt['pillar.get']('global:datastax:opscenter:supported-versions:' + version + ':package', None) %}


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

install opscenter on {{grains['id']}} for {{grains['role']}}:
  cmd.run:
    - name: |
        yum -y update
        yum -y install {{package}}
    - cwd: /home/{{user}}

configure {{product}} service on {{grains['id']}}:
  file.replace:
    - name: /usr/share/opscenter/bin/opscenter
    - pattern: ^JAVA=.*$
    - repl: 'JAVA=/opt/java/latest/bin/java'
    - append_if_not_found: True
    - backup: .original

#START THE SERVICE....

{% endif %}

