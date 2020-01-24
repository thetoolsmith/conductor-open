{% import_yaml "salty/nifi/defaults.yaml" as defaults %}

{% if 'nproc' in defaults.nifi %}
  {% set file_path = salt['pillar.get']('file-path', None) %}
  {% if not file_path == None %}
set {{grains['role']}} nproc limit:
  file.replace:
    - name: {{file_path}}
    - pattern: '^.*          soft    nproc     .*$'
    - repl: '*          soft    nproc     {{defaults.nifi['nproc']}}'
    - backup: .bak
  {% endif %}
{% endif %}



