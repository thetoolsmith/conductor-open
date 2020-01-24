# START DATASTAX AGENT
{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}
{% set svc = 'datastax-agent' %}

stop {{svc}} for {{grains['role']}}:
  module.run:
    - name: service.stop
    - m_name: {{svc}}
