{% set file_path = salt['pillar.get']('file-path', None) %}
{% if not file_path == None %}
set {{grains['role']}} Connect String:
  {% set zoo_hosts = grains['zookeeper.host'] %}
  file.replace:
    - name: {{file_path}}
    - pattern: '<property name="Connect String">.*$'
    - repl: '<property name="Connect String">{{zoo_hosts|join(',')}}</property>'
    - backup: .bak

set {{grains['role']}} Root Node:
  file.replace:
    - name: {{file_path}}
    - pattern: '<property name="Root Node">.*$'
    - repl: '<property name="Root Node">/nifi</property>'
    - backup: .bak

set {{grains['role']}} Session Timeout:
  file.replace:
    - name: {{file_path}}
    - pattern: '<property name="Session Timeout">.*$'
    - repl: '<property name="Session Timeout">10 Seconds</property>'
    - backup: .bak

{% endif %}



