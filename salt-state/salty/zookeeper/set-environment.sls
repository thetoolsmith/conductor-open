{% from "salty/map.jinja" import pgroup with context %}

{% set env_vars = salt['pillar.get']('env-vars', {}) %}
{% set env_alias = {} %}

# ADD VARS AND SET LOCAL ENVIRONMENT
{% set _home = pgroup.zookeeper['dest-path'] + '/' + pgroup.zookeeper['product-name'] %}
{% do env_vars.update({'ZK_HOME': _home}) %}
{% do env_vars.update({'ZK_DATADIR': '"$ZK_HOME/data"'}) %}
{% do env_vars.update({'ZK_DATALOGDIR': '"$ZK_HOME/logs"'}) %}
{% do env_vars.update({'ZOO_LOG_DIR': '"$ZK_HOME/logs"'}) %}

{% for f_ in pgroup.zookeeper['env-file-updates'] %}
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
  # POSITIONAL ENV
export path in {{f_}} {{grains['role']}} on {{grains['id']}}:
  file.append:
    - name: {{f_}}
    - text: |
        export PATH=/opt:$ZK_HOME/bin:$PATH
{% endfor %}

# SET ALIAS ENVIRONMENT
{% do env_alias.update({'startZK': '"sudo service zookeeper start"'}) %}
{% do env_alias.update({'stopZK': '"sudo service zookeeper stop"'}) %}
{% do env_alias.update({'restartZK': '"sudo service zookeeper restart"'}) %}
{% do env_alias.update({'statusZK': '"sudo service zookeeper status"'}) %}
{% do env_alias.update({'goZK': '"cd $ZK_HOME"'}) %}
{% do env_alias.update({'goZKdata': '"cd $ZK_DATADIR"'}) %}
{% do env_alias.update({'goZKlog': '"cd $ZK_DATALOGDIR"'}) %}

{% for f_ in pgroup.zookeeper['env-file-updates'] %}
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
