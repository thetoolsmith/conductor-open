# NIFI - COMMON STATE
# OPTIONAL PILLAR PARAMETERS
# version
# java-version
# dest-path
# sql
# user
# group
# protocol-port
# socket-port 
# role

{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

# OVERWRITES
{% set version = salt['pillar.get']('version', salt['pillar.get']('config.common:apache:nifi:version', nifi['product-version'])) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('config.common:apache:nifi:java:version', nifi['java-version'])) %}
{% set dest_path = salt['pillar.get']('dest-path', nifi['dest-path']) %}
{% set sql = salt['pillar.get']('sql', None) %}
{% set user = salt['pillar.get']('user', nifi['user']) %}
{% set group = salt['pillar.get']('group', nifi['group']) %}
{% set protocol_port = salt['pillar.get']('protocol-port', nifi['protocol-port']) %}
{% set socket_port = salt['pillar.get']('socket-port', nifi['socket-port']) %}
{% set package = salt['pillar.get']('global:apache:nifi:supported-versions:' + version + ':package', nifi['pkg']) %}
{% set product = nifi['product-name'] %}
{% set role = salt['pillar.get']('role', salt['grains.get']('role', product + '_' + grains['id'])) %}

{% set _errors = [] %}
{% if nifi['product-name'] == None %}
  {% do _errors.append('product-name not found in defaults') %}
{% endif %}
{% if package == None %}
  {% do _errors.append('package not found') %}
{% endif %}
{% if version == None %}
  {% do _errors.append('version not found') %}
{% endif %}
{% if nifi['srcpath'] == None %}
  {% do _errors.append('srcpath not found') %}
{% endif %}

{% if version in salt['pillar.get']('global:apache:' + product + ':supported-versions', {}) %}

  {% set package = salt['pillar.get']('global:apache:' + product + ':supported-versions:' + version + ':package', nifi['package']) %}
  {% if package == None %}
    {% do _errors.append('package not found') %}
  {% endif %}

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

create {{dest_path}}/nifi for {{product}}:
  file.directory:
    - name: {{ dest_path }}/nifi
    - makedirs: True
    - user: {{user}}
    - group: {{group}}
    - mode: 755

fetch {{product}} for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}/nifi
    - name: |
        curl {{common.artifactory.connector }}{{nifi['srcpath']}}{{version}}/{{package}} -o {{package}}
        tar zxf {{package}} -C {{dest_path}}/nifi
        rm -rf {{package}}
        mv {{dest_path}}/nifi/nifi* {{dest_path}}/nifi/{{version}}
        mkdir -p {{dest_path}}/nifi/{{version}}/resources
    - unless: test -d {{ dest_path }}/nifi/{{version}}

    {% if not sql == None %}  
fetch sql for {{product}} {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}/nifi/{{version}}/resources
    - name: |
        curl {{common.artifactory.connector}}{{sql}} -O
    {% endif %}

{% else %}
{% do _errors.append('invalid version') %}
invalid version {{version}} common {{product}} abort:
  cmd.run:
    - name: |
        {% for e in _errors %}
        echo {{e}}
        {% endfor %}
  module.run:
    - name: test.false
{% endif %}
