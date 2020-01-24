{% import_yaml "salty/nifi/defaults.yaml" as defaults %}

{% if 'bootstrap-conf' in defaults.nifi %}
  {% set properties = defaults.nifi['bootstrap-conf'] %}
  {% set file_path = salt['pillar.get']('file-path', None) %}
  {% if not file_path == None %}
    {% for prop,val in properties.iteritems() %}
set {{grains['role']}} {{prop}}:
  file.replace:
    - name: {{file_path}}
    - pattern: =-{{prop}}.*$
    - repl: =-{{prop}}{{val}}
    - backup: .bak
    {% endfor %}
  {% endif %}
{% endif %}



