{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}

{% set env_vars = salt['pillar.get']('env-vars', {}) %}
{% set env_alias = {} %}

# ADD VARS AND SET LOCAL ENVIRONMENT
{% do env_vars.update({'DSE_DIR': 'cassandra'}) %}
{% do env_vars.update({'DSE_HOME': defaults.cassandra['home']}) %}

{% for f_ in defaults.cassandra['env-file-updates'] %}
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
{% do env_alias.update({'goDSE': '"cd $DSE_HOME"'}) %}
{% do env_alias.update({'startDSE': '"sudo service dse start"'}) %}
{% do env_alias.update({'stopDSE': '"sudo service dse stop"'}) %}
{% do env_alias.update({'restartDSE': '"stopDSE; startDSE"'}) %}
{% do env_alias.update({'statusDSE': '"sudo servive dse status"'}) %}
{% for f_ in defaults.cassandra['env-file-updates'] %}
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
