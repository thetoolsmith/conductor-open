# ZOOKEEPER - COMMON STATE
# OPTIONAL PILLAR PARAMETERS
# version
# java-version
# dest-path
# zoofile
# user
# group

{% from "common/map.jinja" import common with context %}
{% from "common/apache/zookeeper/map.jinja" import zookeeper with context %}

# OVERWRITES
{% set version = salt['pillar.get']('version', zookeeper['version']) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('config.common:apache:zookeeper:java:version', zookeeper['java-version'])) %}
{% set dest_path = salt['pillar.get']('dest-path', zookeeper['dest-path']) %}
{% set zoofile = salt['pillar.get']('zoofile', None) %}
{% set user = salt['pillar.get']('user', zookeeper['user']) %}
{% set group = salt['pillar.get']('group', zookeeper['group']) %}
{% set package = salt['pillar.get']('global:apache:zookeeper:supported-versions:' + version + ':package', zookeeper['pkg']) %}

{% set _errors = [] %}
{% if zookeeper['product-name'] == None %}
  {% do _errors.append('product-name not found in defaults') %}
{% endif %}

{% if package == None %}
  {% do _errors.append('package not found') %}
{% endif %}

{% set product = zookeeper['product-name'] %}

{% if version == None %}
  {% do _errors.append('version not found') %}
{% endif %}

{% if zookeeper['srcpath'] == None %}
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

create {{dest_path}} for {{product}}:
  file.directory:
    - name: {{ dest_path }}
    - makedirs: True
    - user: {{user}}
    - group: {{group}}
    - mode: 755

fetch {{product}} for {{grains['id']}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}
    - name: |
        curl {{common.artifactory.connector }}{{zookeeper['srcpath']}}{{version}}/{{package}} -o {{package}}
        tar zxf {{package}} -C {{dest_path}}
        rm -rf {{package}}

change default product dir for {{product}} {{version}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}
    - name: |
        mv zookeeper-* zookeeper
    - unless: test -d {{ dest_path }}/zookeeper

create local configuration file for {{product}} {{version}}: 
  module.run:
    - name: state.sls
    - mods: common.apache.{{product}}.create-config
    - kwargs: {
          pillar: {
            dest-path: {{ dest_path }},
{% if not zoofile == None %}
            zoofile: '{{ zoofile }}',
{% endif %}
            user: {{ user }},
            group: {{ group }}
          }   
      }
    - onlyif: test -d {{ dest_path }}/zookeeper/conf

{% set myid = grains['cluster.members.info'][grains['id']]['member_id'] %}
deploy id file on {{grains['id']}}:
  file.managed:
    - name: {{dest_path}}/myid
    - makedirs: True
    - replace: True
    - user: {{user}}
    - group: {{group}}
    - contents: |
        {{myid}}
    - backup: False

update service configuration file for {{product}} {{version}}: 
  module.run:
    - name: state.sls
    - mods: common.apache.{{product}}.update-service
    - kwargs: {
          pillar: {
            dest-path: {{dest_path}},
            user: {{user}},
            product: {{product}}
          }   
      }
    - onlyif: test -d {{ dest_path }}/zookeeper/bin

# DO NOT START THE SERVICE, LET CONSUMING STATE DO THAT

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
