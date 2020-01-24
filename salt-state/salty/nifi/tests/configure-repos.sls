{% from "common/apache/nifi/map.jinja" import nifi with context %}
{% import_yaml "salty/nifi/defaults.yaml" as defaults %}
{% from "common/map.jinja" import common with context %}

{% set env_vars = {} %}
{% set version = salt['pillar.get']('version', defaults.nifi['product-version']) %}

{% set repos = nifi['repos'] %}
{% for repo in repos %}
  {% do env_vars.update({'NIFI_' + repo[:-6]|replace('database', 'DB')|upper: defaults.nifi['home'] + '/nifi_' + repo}) %}
test show {{repo}} for salty.nifi:
  cmd.run:
    - name: |
        echo NIFI REPO {{repo}}
        {% for k,v in env_vars.iteritems() %}
        echo {{k}} ----- {{v}}
        {% endfor %}


  {% if not salt['file.directory_exists' ](defaults.nifi['home'] + '/' + repo) %}
test create link for {{repo}} for salty.nifi:
  file.symlink:
    - name: {{defaults.nifi['home']}}/{{repo}}
    - target: /nifi_{{repo}}/{{version}}/{{repo}}
    - user: {{defaults.nifi['appuser']}}
    - group: {{defaults.nifi['appgroup']}}
    - unless: test -d {{defaults.nifi['home']}}/{{repo}}

  {% endif %}

{% endfor %}

