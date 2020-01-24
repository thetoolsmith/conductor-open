# KAFKA - COMMON STATE
# OPTIONAL PILLAR PARAMETERS
# version
# java-version
# dest-path
# server-properties (list)
# user
# group
# role

{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

# OVERWRITES
{% set version = salt['pillar.get']('version', salt['pillar.get']('config.common:apache:kafka:version', kafka['product-version'])) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('config.common:apache:kafka:java:version', kafka['java-version'])) %}
{% set dest_path = salt['pillar.get']('dest-path', kafka['dest-path']) %}
{% set server_properties = salt['pillar.get']('server-properties', {}) %}
{% set user = salt['pillar.get']('user', kafka['user']) %}
{% set group = salt['pillar.get']('group', kafka['group']) %}
{% set package = salt['pillar.get']('global:apache:kafka:supported-versions:' + version + ':package', kafka['pkg']) %}
{% set product = kafka['product-name'] %}
{% set role = salt['pillar.get']('role', salt['grains.get']('role', product + '_' + grains['id'])) %}

# SET VARS BASED ON DISTRO
{% set conf_dir = dest_path + '/kafka/config' %}
{% set exec_run_class = dest_path + '/kafka/bin/kafka-run-class.sh' %}
{% set exec_start = dest_path + '/kafka/bin/kafka-server-start.sh' %}
{% set exec_topic = dest_path + '/kafka/bin/kafka-topics.sh' %}
{% if 'confluent' in version %}
  {% set conf_dir = dest_path + '/kafka/etc/kafka' %} 
  {% set exec_run_class = dest_path + '/kafka/bin/kafka-run-class' %}
  {% set exec_start = dest_path + '/kafka/bin/kafka-server-start' %}
  {% set exec_topic = dest_path + '/kafka/bin/kafka-topics' %}
{% endif %}

{% set _errors = [] %}
{% if kafka['product-name'] == None %}
  {% do _errors.append('product-name not found in defaults') %}
{% endif %}
{% if package == None %}
  {% do _errors.append('package not found') %}
{% endif %}
{% if version == None %}
  {% do _errors.append('version not found') %}
{% endif %}
{% if kafka['srcpath'] == None %}
  {% do _errors.append('srcpath not found') %}
{% endif %}

{% if version in salt['pillar.get']('global:apache:' + product + ':supported-versions', {}) %}

  {% set package = salt['pillar.get']('global:apache:' + product + ':supported-versions:' + version + ':package', kafka['package']) %}
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

create {{dest_path}} for {{product}}:
  file.directory:
    - name: {{ dest_path }}
    - makedirs: True
    - user: {{user}}
    - group: {{group}}
    - dir_mode: 755
    - file_mode: 744
    - recurse:
      - user
      - group
      - mode

remove previous {{product}} version on {{grains['id']}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{dest_path}}
    - name: |
        rm -rf kafka
    - onlyif: test -d {{dest_path}}/kafka

fetch {{product}} for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}
    - name: |
        curl {{common.artifactory.connector }}{{kafka['srcpath']}}{{version}}/{{package}} -o {{dest_path}}/{{package}}
        tar zxf {{package}}
        rm -rf {{package}}
        mv {{package[:5]}}* kafka

update {{product}} {{version}} server config:
  module.run:
    - name: state.sls
    - mods: common.apache.kafka.update-server-properties
    - kwargs: {
          pillar: {
            file-path: {{conf_dir}}/server.properties,
            properties: {{ server_properties }}
          }   
      } 

update {{product}} {{version}} service config:
  module.run:
    - name: state.sls
    - mods: common.apache.kafka.update-service
    - kwargs: {
          pillar: {
            file-path: {{exec_run_class}},
            user: {{ user }}
          }
      }

start {{ product }} {{ version }} server:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}/{{ product }}/bin
    - name: |
        {{exec_start}} -daemon {{conf_dir}}/server.properties

verify {{product}} {{version}} communications:
  module.run:
    - name: state.sls
    - mods: common.apache.kafka.create-test-topic
    - kwargs: {
          pillar: {
            file-path: {{exec_topic}}
          }   
      } 

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
