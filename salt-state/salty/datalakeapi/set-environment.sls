{% import_yaml "salty/datalakeapi/defaults.yaml" as defaults %}

{% set env_vars = salt['pillar.get']('env-vars', {}) %}
{% set env_alias = {} %}

# ADD VARS AND SET LOCAL ENVIRONMENT
{% do env_vars.update({'REST_API_HOME': defaults.datalakeapi['dest-path'] + '/' + defaults.datalakeapi['product-name']}) %}
{% do env_vars.update({'LOG_DIR': '/datalake_logdir/' + defaults.datalakeapi['product-name'] + '/logs'}) %}

{% for f_ in defaults.datalakeapi['env-file-updates'] %}
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
{% do env_alias.update({'goPlay': '"cd $REST_API_HOME"'}) %}
{% do env_alias.update({'goPlayLogs': '"cd $LOG_DIR"'}) %}
{% do env_alias.update({'startPlay': '"sudo systemctl start datalake_rest_api_ssl"'}) %}
{% do env_alias.update({'stopPlay': '"sudo systemctl stop datalake_rest_api_ssl"'}) %}
{% do env_alias.update({'restartPlay': '"sudo systemctl restart datalake_rest_api_ssl"'}) %}
{% do env_alias.update({'statusPlay': '"sudo systemctl status datalake_rest_api_ssl"'}) %}
{% for f_ in defaults.datalakeapi['env-file-updates'] %}
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
