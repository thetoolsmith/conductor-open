{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

{% set dest_path = salt['pillar.get']('dest-path', nifi['dest-path'] + '/nifi/' + nifi['product-version']) %}

test.stop nifi service:
  cmd.run: 
    - name: |
        {{ dest_path }}/bin/nifi.sh stop
        echo stopped....

test.start nifi service:
  cmd.run:
    - name: |
        {{ dest_path }}/bin/nifi.sh start
        disown
    - bg: True
