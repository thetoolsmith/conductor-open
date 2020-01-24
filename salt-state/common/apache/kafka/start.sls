{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set dest_path = salt['pillar.get']('dest-path', kafka['dest-path']) %}
{% set start = './kafka-server-start.sh -daemon ../config/server.properties' %}

start kafka server:
  cmd.run:
    - name: |
        {{ start }}
    - cwd: {{ dest_path }}/kafka/bin
