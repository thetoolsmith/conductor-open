{% from "common/apache/zookeeper/map.jinja" import zookeeper with context %}

{% set znode = salt['pillar.get']('znode', None) %}
{% set role = salt['pillar.get']('role', 'unspecified') %}
{% set zoo_bin = salt['pillar.get']('zoo-bin', zookeeper['dest-path'] + '/zookeeper/bin/zkCli.sh') %}
# NEED TO CHANGE COMMAND TO USE ALIAS FOR zkCli.sh
common.apache.zookeeper create znode for {{ role }}:
  cmd.run:
    - name: |
        {{zoo_bin}} -server {{grains['ipv4'][0]}} create /{{znode}}

