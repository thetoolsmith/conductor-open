{% import_yaml "salty/nifi/defaults.yaml" as defaults %}

{% if 'properties' in defaults.nifi %}
  {% set properties = defaults.nifi['properties'] %}
  {% set file_path = salt['pillar.get']('file-path', None) %}
  {% if not file_path == None %}
 
    {% for prop,val in properties.iteritems() %}
set {{grains['role']}} {{prop}}:
  file.replace:
    - name: {{file_path}}
    - pattern: {{prop}}=.*$
      {% if prop == 'nifi.provenance.repository.indexed.attributes' %}
    - repl: {{prop}}={{val|join(',')}}
      {% else %}
    - repl: {{prop}}={{val}}
      {% endif %}
    - backup: .bak
    {% endfor %}
  # ADD DYNAMIC VALUE PROPERTIES
set {{grains['role']}} nifi.cluster.node.address:
  file.replace:
    - name: {{file_path}}
    - pattern: nifi.cluster.node.address=.*$
    - repl: nifi.cluster.node.address={{grains['ipv4'][0]}}
    - backup: .bak

set {{grains['role']}} nifi.web.http.host:
  file.replace:
    - name: {{file_path}}
    - pattern: nifi.web.http.host=.*$
    - repl: nifi.web.http.host={{grains['ipv4'][0]}}
    - backup: .bak

set {{grains['role']}} nifi.remote.input.host:
  file.replace:
    - name: {{file_path}}
    - pattern: nifi.remote.input.host=.*$
    - repl: nifi.remote.input.host={{grains['ipv4'][0]}}
    - backup: .bak

set {{grains['role']}} nifi.zookeeper.connect.string:
    {% set zoo_hosts = grains['zookeeper.host'] %}
  file.replace:
    - name: {{file_path}}
    - pattern: nifi.zookeeper.connect.string=.*$
    - repl: nifi.zookeeper.connect.string={{ zoo_hosts|join(',') }}
    - backup: .bak

  {% endif %}
{% endif %}



