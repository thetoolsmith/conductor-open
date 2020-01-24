# START DATASTAX AGENT
{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}
{% set svc = 'datastax-agent' %}

configure {{svc}} for {{grains['role']}}:
  file.replace:
    - name: /usr/share/datastax-agent/bin/datastax-agent
    - pattern: ^JAVA=.*$
    - repl: 'JAVA=$JAVA'
    - append_if_not_found: True
    - backup: .original

start {{svc}} for {{grains['role']}}:
  module.run:
    - name: service.start
    - m_name: {{svc}}

status {{svc}} for {{grains['role']}}:
  module.run:
    - name: service.status
    - m_name: {{svc}}
