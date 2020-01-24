# UPDATE address.yaml STATE
{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}

{% set role = grains['role'] %}
{% set product = role.split('.')[1] %}
{% set file_path = salt['pillar.get']('file-path', None) %}

{% if not file_path == None %}
  {% if 'datastax-agent' in defaults.cassandra %}
    {% set agent_conf = defaults.cassandra['datastax-agent'] %}
set {{grains['role']}} {{file_path}} datastax-agent swagger_enabled:
  file.replace:
    - name: {{file_path}}
    - pattern: '^(#|s).*wagger_enabled:.*$'
    - repl: "swagger_enabled: {{agent_conf['swagger_enabled']}}"
    - append_if_not_found: True
    - backup: .original

set {{grains['role']}} {{file_path}} datastax-agent api-port:
  file.replace:
    - name: {{file_path}}
    - pattern: '^(#|a).*pi_port:.*$'
    - repl: "api_port: {{agent_conf['api_port']}}"
    - append_if_not_found: True
    - backup: .bak

  {% endif %}
{% endif %}



