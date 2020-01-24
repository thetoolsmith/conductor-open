# VERIFY KAFKA CLUSTER -> ZOOKEEPER COMMUNICATE
# CREATES A UNIQUE TEST TOPIC USING CUSTOM GRAINS FOR TOPIC NAME
# DESCRIBES THEN DELETES THE TOPIC.
# THIS STATE CAN BE RUN OVER AND OVER
{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set file_path = salt['pillar.get']('file-path', kafka['dest-path'] + '/kafka/bin/kafka-topics.sh') %}
{% set exec = file_path.split('/')|last|join('') %}
{% set unpad = exec|length + 1 %}
{% set dest_path = file_path[:-unpad] %}
{% set topic = salt['grains.get']('cpid')|string + '_' + salt['grains.get']('cluster.member.id')|string %}
{% set partitions = salt['pillar.get']('partitions', 1) %}
{% set replication = salt['pillar.get']('replication-factor', 1) %}
{% set zoo_hosts = salt['grains.get']('zookeeper.host') %}
{% set host_suffix = '/kafka' + salt['grains.get'](salt['grains.get']('role') + '.cluster.id')|string %}
{% set zoo_connect = zoo_hosts|join(',') + host_suffix %}
{% set create_topic = './' + exec + ' --create --zookeeper ' + zoo_connect + ' --replication-factor ' + replication|string + ' --partitions ' + partitions|string + ' --topic test-topic-' + topic %}
{% set describe_topic = './' + exec + ' --describe --zookeeper ' + zoo_connect + ' --topic test-topic-' + topic %}
{% set delete_topic = './' + exec + ' --delete --zookeeper ' + zoo_connect + ' --topic test-topic-' + topic %}

verify kafka with create topic {{topic}}:
  cmd.run:
    - name: |
        {{create_topic}}
    - cwd: {{dest_path}}

verify kafka with describe topic {{topic}}:
  cmd.run:
    - name: |
        {{describe_topic}}
    - cwd: {{dest_path}}
       
verify kafka with delete topic {{topic}}:
  cmd.run:
    - name: |
        {{delete_topic}}
    - cwd: {{dest_path}}

