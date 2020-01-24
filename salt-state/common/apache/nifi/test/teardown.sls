{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

{% set dest_path = salt['pillar.get']('dest-path', nifi['dest-path'] + '/nifi/' + nifi['product-version']) %}

test.rollback nifi.web.http.host:
  file.replace:
    - name: {{ dest_path }}/conf/nifi.properties
    - pattern: ^nifi.web.http.host=.*$
    - repl: nifi.web.http.host=
    - backup: .rollbak

test.teardown.restart nifi service:
  module.run:
    - name: state.sls
    - mods: common.apache.nifi.test.restart
    - kwargs: {
          pillar: {
            dest-path: {{ dest_path }}
          }   
      }
