{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

# OVERWRITES
{% set properties = salt['pillar.get']('properties', nifi['properties']) %}
{% set prop_timeout = properties['nifi.zookeeper.connect.timeout'] %}


test properties for nifi:
  cmd.run:
    - name: |
        echo properties {{properties}}
        echo prop_timeout {{prop_timeout}}

