{% import_yaml "salty/nifi/defaults.yaml" as defaults %}

{% set file_path = salt['pillar.get']('file-path', None) %}
{% if not file_path == None %}
  {% if 'logback-xml' in defaults.nifi %}
    {% set properties = defaults.nifi['logback-xml'] %}
    {% for prop,val in properties.iteritems() %}
set {{grains['role']}} {{prop}} property:
  file.replace:
    - name: {{file_path}}
    - pattern: <{{prop}}>.*$
    - repl: <{{prop}}>{{val}}</{{prop}}>
    - backup: .bak
    {% endfor %}
  {% endif %}
{% endif %}



