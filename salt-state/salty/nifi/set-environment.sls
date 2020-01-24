{% import_yaml "salty/nifi/defaults.yaml" as defaults %}

{% set env_vars = salt['pillar.get']('env-vars', {}) %}
{% set env_alias = {} %}

# ADD VARS AND SET LOCAL ENVIRONMENT
{% do env_vars.update({'DSBULK_HOME': defaults.nifi['dest-path'] + '/dsbulk/' + defaults.nifi['dsbulk-version']}) %}
{% set update_path = defaults.nifi['dest-path'] + '/dsbulk/' + defaults.nifi['dsbulk-version'] + '/bin:' + salt['environ.get']('PATH') %}
{% do env_vars.update({'PATH': update_path}) %}
{% do env_vars.update({'NIFI_HOME': defaults.nifi['home']}) %}

{% for f_ in defaults.nifi['env-file-updates'] %}
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
{% do env_alias.update({'goNifi': '"cd $NIFI_HOME"'}) %}
{% do env_alias.update({'startNifi': '"sudo service nifi start"'}) %}
{% do env_alias.update({'stopNifi': '"sudo service nifi stop"'}) %}
{% do env_alias.update({'restartNifi': '"sudo service nifi restart"'}) %}
{% do env_alias.update({'statusNifi': '"sudo service nifi status"'}) %}
{% for f_ in defaults.nifi['env-file-updates'] %}
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
