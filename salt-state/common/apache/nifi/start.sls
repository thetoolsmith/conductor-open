{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

{% set dest_path = salt['pillar.get']('dest-path', nifi['dest-path']) %}
{% set product = salt['pillar.get']('product', nifi['product-name']) %}

start nifi service:
  cmd.run:
    - name: |
        service nifi start
    - bg: True
