{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set dest_path = salt['pillar.get']('dest-path', kafka['dest-path']) %}
{% set stop = './kafka-server-stop.sh ../config/server.properties' %}

stop kafka server:
  cmd.run:
    - name: |
        {{ stop }}
    - cwd: {{ dest_path }}/kafka/bin
