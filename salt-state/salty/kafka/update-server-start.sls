# UPDATE kafka-server-start STATE
{% from "salty/map.jinja" import pgroup with context %}

{% set file_path = salt['pillar.get']('file-path',  pgroup.kafka['dest-path'] + '/kafka/bin/kafka-server-start') %}
{% set skip = salt['file.search'](file_path, 'export JMX_PORT=' + pgroup.kafka['server-properties']['jmx-port']|string) %}

{% if not file_path == None and 'jmx-port' in pgroup.kafka['server-properties'] and not skip %}
{{file_path}} set jmx-port:
  file.replace:
    - name: {{file_path}}
    - pattern: {{'exec $base_dir/kafka-run-class' | regex_escape}}
    - repl: export JMX_PORT={{pgroup.kafka['server-properties']['jmx-port']}}\nexec $base_dir/kafka-run-class
    - backup: .bak
  
{% endif %}

