{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

{% set dest_path = salt['pillar.get']('dest-path', nifi['dest-path'] + '/nifi/' + nifi['product-version']) %}
{% set ipaddr = salt['grains.get']('ipv4')[0] %}

test.prepare nifi.web.http.host:
  file.replace:
    - name: {{ dest_path }}/conf/nifi.properties
    - pattern: ^nifi.web.http.host=.*$
    - repl: nifi.web.http.host={{ipaddr}}
    - backup: .bak

test.setup.restart nifi service:
  module.run:
    - name: state.sls
    - mods: common.apache.nifi.test.restart

