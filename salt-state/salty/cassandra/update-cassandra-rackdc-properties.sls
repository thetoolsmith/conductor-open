# UPDATE cassandra-rackdc.properties STATE

{% set role = grains['role'] %}
{% set product = role.split('.')[1] %}
{% set file_path = salt['pillar.get']('file-path', None) %}

{% if not file_path == None %}
 
set {{grains['role']}} dc:
  {% set unique_id = grains[grains['role'] + '.cluster.id']|string %}
  file.replace:
    - name: {{file_path}}
    - pattern: ^dc=.*$
    - repl: dc={{role.split('.')[0]}}-{{role.split('.')[1]}}-{{grains['pillar.environment']}}-{{unique_id}}-dc
    - backup: .bak

set {{grains['role']}} rack:
  file.replace:
    - name: {{file_path}}
    - pattern: ^rack=.*$
    - repl: rack={{grains['node_location']}}
    - backup: .bak

{% endif %}



