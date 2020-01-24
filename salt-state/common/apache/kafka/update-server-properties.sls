{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set file_path = salt['pillar.get']('file-path', kafka['dest-path'] + '/kafka/conf/server.properties') %}
{% set properties = salt['pillar.get']('properties', {}) %}

{% set listener = salt['pillar.get']('properties:listener', kafka['listener']) %}
{% set listener_port = salt['pillar.get']('properties:listener-port', kafka['listener-port']) %}
{% set num_partitions = salt['pillar.get']('properties:num-partitions', kafka['num-partitions']) %}
{% set log_dirs = salt['pillar.get']('properties:log-dirs', kafka['log-dirs']) %}
{% set jmx_port = salt['pillar.get']('properties:jmx-port', None) %}
{% set delete_topics = salt['pillar.get']('properties:delete-topics', 'False') %}

update kafka server.properties listener:
  file.replace:
    - name: {{file_path}}
    - pattern: ^#listeners=PLAIN.*$
    - repl: listeners={{listener}}://{{grains['ipv4'][0]}}:{{listener_port}}
    - backup: .bak

update kafka server.properties broker id:
  file.replace:
    - name: {{file_path}}
    - pattern: ^broker.id=.*$
    - repl: broker.id={{grains['cluster.member.id']}}
    - backup: .bak

update kafka server.properties num partitions:
  file.replace:
    - name: {{file_path}}
    - pattern: ^num.partitions=.*$
    - repl: num.partitions={{ num_partitions }}
    - backup: .bak

{% set log_paths = log_dirs|join(',') %}

update kafka server.properties log dirs:
  file.replace:
    - name: {{file_path}}
    - pattern: ^log.dirs=.*$
    - repl: log.dirs={{ log_paths }}
    - backup: .bak

{% if not jmx_port == None %}
update kafka server.properties jmx.port:
  file.replace:
    - name: {{file_path}}
    - append_if_not_found: True
    - pattern: ^jmx.port=.*$
    - repl: jmx.port={{jmx_port}}
    - backup: .bak
update kafka server.properties jmx.hostname:
  file.replace:
    - name: {{file_path}}
    - append_if_not_found: True
    - pattern: ^jmx.hostname=.*$
    - repl: jmx.hostname={{grains['ipv4'][0]}}
    - backup: .bak
{% endif %}

update kafka server.properties delete-topics:
  file.replace:
    - name: {{file_path}}
    - append_if_not_found: True
    - pattern: ^delete.topics.enable=.*$
    - repl: delete.topics.enable={{delete_topics}}
    - backup: .bak

{% set zoo_hosts = grains['zookeeper.host'] %}
{% set host_suffix = '/kafka' + grains[grains['role'] + '.cluster.id']|string %}
update kafka server.properties zookeeper connect:
  file.replace:
    - name: {{file_path}}
    - pattern: ^zookeeper.connect=.*$
    - repl: zookeeper.connect={{ zoo_hosts|join(',') }}{{host_suffix}}
    - backup: .bak

