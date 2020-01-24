# UPDATE dse-env.sh STATE

{% set role = grains['role'] %}
{% set product = role.split('.')[1] %}
{% set file_path = salt['pillar.get']('file-path', None) %}

{% if not file_path == None %}
  # ORDER SPECIFIC
  {% set java_home_set = salt['file.search'](file_path, 'export java_home=') %}
  {% if java_home_set == True %}
update {{grains['role']}} dse-env java_home and PATH:
  file.replace:
    - name: {{file_path}}
    - pattern: '^export java_home=.*$'
    {% set path_set = salt['file.search'](file_path, 'export PATH=') %}
    {% if path_set == False %}
    - repl: 'export java_home=/opt/java8\nexport PATH=${java_home}/bin:${PATH}'
    {% else %}
    - repl: 'export java_home=/opt/java8'
    {% endif %}
    - backup: .bak
  {% else %}
remove {{grains['role']}} dse-env PATH:
  file.replace:
    - name: {{file_path}}
    - pattern: '^export PATH=.*$'
    - repl: ''

    {% set path_set = salt['file.search'](file_path, 'export PATH=${java_home}/bin:${PATH}') %}
    {% if path_set == False %}
set {{grains['role']}} dse-env PATH:
  file.replace:
    - name: {{file_path}}
    - pattern: '^# may set thirdparty variables.*$'
    - repl: '# may set thirdparty variables.\nexport PATH=${java_home}/bin:${PATH}'
    - backup: .bak
    {% endif %}
set {{grains['role']}} dse-env java_home:
  file.replace:
    - name: {{file_path}}
    - pattern: '^# may set thirdparty variables.*$'
    - repl: '# may set thirdparty variables.\nexport java_home=/opt/java8'
    - backup: .bak
  {% endif %}


   # NO ORDER SPECIFIC
  {% set skipupdate = salt['file.search'](file_path, 'export DSE_LOG_DIR=/datalake/cassandra/logs') %}
  {% if skipupdate == False %}
set {{grains['role']}} dse-env DSE_LOG_DIR:
  file.replace:
    - name: {{file_path}}
    - pattern: '^# may set thirdparty variables.*$'
    - repl: '# may set thirdparty variables.\nexport DSE_LOG_DIR=/datalake/cassandra/logs'
    - backup: .bak
  {% endif %}

  {% set skipupdate = salt['file.search'](file_path, 'export CASSANDRA_LOG_DIR=/datalake/cassandra/logs') %}
  {% if skipupdate == False %}
set {{grains['role']}} dse-env CASSANDRA_LOG_DIR:
  file.replace:
    - name: {{file_path}}
    - pattern: '^# may set thirdparty variables.*$'
    - repl: '# may set thirdparty variables.\nexport CASSANDRA_LOG_DIR=/datalake/cassandra/logs'
    - backup: .bak
  {% endif %}
{% endif %}



