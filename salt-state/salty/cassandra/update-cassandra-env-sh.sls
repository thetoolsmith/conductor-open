# UPDATE cassandra-env.sh STATE
{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}

{% set role = grains['role'] %}
{% set product = role.split('.')[1] %}
{% set file_path = salt['pillar.get']('file-path', None) %}

{% if not file_path == None %}

set {{grains['role']}} com.sun.management.jmxremote.password.file:
  {% set home = defaults.cassandra['home'] %}
  file.replace:
    - name: {{file_path}}
    - pattern: com.sun.management.jmxremote.password.file=.*$
    - repl: 'com.sun.management.jmxremote.password.file={{home}}/jmxremote.password"'
    - backup: .bak

set {{grains['role']}} com.sun.management.jmxremote.access.file:
  file.replace:
    - name: {{file_path}}
    - pattern: com.sun.management.jmxremote.access.file=.*$
    - repl: 'com.sun.management.jmxremote.access.file=/opt/java8/jre/lib/management/jmxremote.access"'
    - backup: .bak 

  {% set skipupdate = salt['file.search'](file_path, 'export CASSANDRA_HEAPDUMP_DIR=/datalake/dump/cassandra') %}
  {% if skipupdate == False %}
set {{grains['role']}} client_encryption_options enabled:
  file.replace:
    - name: {{file_path}}
    - pattern: ^# set jvm HeapDumpPath with CASSANDRA_HEAPDUMP_DIR.*$
    - repl: '# set jvm HeapDumpPath with CASSANDRA_HEAPDUMP_DIR\nexport CASSANDRA_HEAPDUMP_DIR=/datalake/dump/cassandra'
    - backup: .bak
  {% endif %}
{% endif %}



