{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set file_path = '/datalake/kafka/bin/kafka-topics' %}
{% set exec = file_path.split('/')|last|join('') %}
{% set unpad = exec|length + 1 %}
{% set dest_path = file_path[:-unpad] %}
{% set topic = salt['pillar.get']('topic', 'not-specified') %}
{% set partitions = salt['pillar.get']('partitions', 1) %}
{% set replication = salt['pillar.get']('replication-factor', 1) %}

{% set zoo_hosts = salt['grains.get']('zookeeper.host') %}
{% set host_suffix = '/kafka' + salt['grains.get']('role' + '.cluster.id', '99')|string %}
{% set zoo_connect = zoo_hosts|join(host_suffix + ',') + host_suffix %}
{% set create_topic = './' + exec + ' --create --zookeeper ' + zoo_connect + ' --replication-factor ' + replication|string + ' --partitions ' + partitions|string + ' --topic ' + topic %}

test ... evaluate grains:
  cmd.run:
    - name: |
        echo {{zoo_hosts}}
        echo {{host_suffix}}
        echo {{zoo_connect}}
        echo {{dest_path}}
        echo {{create_topic}}

test ... kafka {{host_suffix}} kafka create topic {{topic}}:
  cmd.run:
    - name: |
        {{create_topic}}
    - cwd: {{dest_path}}
