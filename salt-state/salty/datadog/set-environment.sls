# ########################################
# GROUP SPECIFIC DATADOG ENVIRONMENT SETUP
# Pillar parameters
# user
# ########################################
{% import_yaml "salty/datadog/defaults.yaml" as defaults %}
{% set user = salt['pillar.get']('user', defaults.datadog['user']) %}
{% set env_alias = {} %}

# SET ALIAS ENVIRONMENT
{% do env_alias.update({'goagentconf': '"pushd /etc/dd-agent"'}) %}
{% do env_alias.update({'gointegrationconf': '"pushd /etc/dd-agent/conf.d"'}) %}
{% do env_alias.update({'ddinfo': '"sudo /etc/init.d/datadog-agent info"'}) %}
{% do env_alias.update({'ddrestart': '"sudo /etc/init.d/datadog-agent restart"'}) %}
{% for f_ in defaults.datadog['env-file-updates'] %}
  {% set user_file = f_|replace("__USER__", user) %}
  {% for a_,v_ in env_alias.iteritems() %}
set alias {{a_}} in {{user_file}} for {{grains['role']}}:
  file.replace:
    - name: {{user_file}}
    - pattern: ^alias {{a_}}=.*$
    - repl: alias {{a_}}={{v_}}
    - append_if_not_found: True
    - backup: .bak
    - onlyif: test -f {{user_file}}
  {% endfor %}
{% endfor %}
