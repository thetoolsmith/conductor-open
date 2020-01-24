# KAFKA CREATE TOPIC STATE

{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set file_path = salt['pillar.get']('file-path', kafka['dest-path'] + '/kafka/bin/kafka-topics.sh') %}
{% set exec = file_path.split('/')|last|join('') %}
{% set unpad = exec|length + 1 %}
{% set dest_path = file_path[:-unpad] %}
{% set topic = salt['pillar.get']('topic', 'not-specified') %}
{% set partitions = salt['pillar.get']('partitions', 1) %}
{% set replication = salt['pillar.get']('replication-factor', 1) %}
{% set zoo_hosts = salt['grains.get']('zookeeper.host') %}
{% set host_suffix = '/kafka' + salt['grains.get'](salt['grains.get']('role') + '.cluster.id')|string %}
{% set zoo_connect = zoo_hosts|join(host_suffix + ',') + host_suffix %}
{% set create_topic = './' + exec + ' --create --zookeeper ' + zoo_connect + ' --replication-factor ' + replication|string + ' --partitions ' + partitions|string + ' --topic ' + topic %}

kafka {{host_suffix}} kafka create topic {{topic}}:
  cmd.run:
    - name: |
        {{create_topic}}
    - cwd: {{dest_path}}

