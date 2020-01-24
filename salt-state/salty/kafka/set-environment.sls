{% from "salty/map.jinja" import pgroup with context %}

{% set env_vars = salt['pillar.get']('env-vars', {}) %}
{% set env_alias = {} %}

# ADD VARS AND SET LOCAL ENVIRONMENT
{% set _home = pgroup.kafka['dest-path'] + '/kafka' %}
{% do env_vars.update({'CONFLUENT_HOME': _home}) %}
{% do env_vars.update({'KAFKA_HEAP_OPTS': '"-Xmx1G -Xms1G"'}) %}
{% do env_vars.update({'JMX_PORT': pgroup.kafka['server-properties']['jmx-port']}) %}
{% do env_vars.update({'LOG_DIR': '/datalake_logdir_1'}) %}

{% for f_ in pgroup.kafka['env-file-updates'] %}
  {% for e_,v_ in env_vars.iteritems() %}
set local {{e_}} in {{f_}} for {{grains['role']}}:
  file.replace:
    - name: {{f_}}
    - pattern: ^export {{e_}}=.*$
    - repl: export {{e_}}={{v_}}
    - append_if_not_found: True
    - backup: .bak
    - onlyif: test -f {{f_}}
  {% endfor %}
{% endfor %}

# SET ALIAS ENVIRONMENT
{% do env_alias.update({'startKafka': '"sudo service kafka start"'}) %}
{% do env_alias.update({'stopKafka': '"sudo service kafka stop"'}) %}
{% do env_alias.update({'restartKafka': '"sudo service kafka restart"'}) %}
{% do env_alias.update({'statusKafka': '"sudo service kafka status"'}) %}
{% do env_alias.update({'goKafka': '"cd $CONFLUENT_HOME"'}) %}
{% do env_alias.update({'listkafkatopics': '"$CONFLUENT_HOME/bin/kafka-topics --list --zookeeper localhost:2181"'}) %}

{% for f_ in pgroup.kafka['env-file-updates'] %}
  {% for a_,v_ in env_alias.iteritems() %}
set alias {{a_}} in {{f_}} for {{grains['role']}}:
  file.replace:
    - name: {{f_}}
    - pattern: ^alias {{a_}}=.*$
    - repl: alias {{a_}}={{v_}}
    - append_if_not_found: True
    - backup: .bak
    - onlyif: test -f {{f_}}
  {% endfor %}
{% endfor %}
