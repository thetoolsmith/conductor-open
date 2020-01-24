{% from "common/map.jinja" import common with context %}
{% from "common/apache/kafka/map.jinja" import kafka with context %}

{% set file_path = salt['pillar.get']('file-path', kafka['dest-path'] + '/kafka/bin/kafka-run-class.sh') %}
{% set product = salt['pillar.get']('product', kafka['product-name']) %}
{% set user = salt['pillar.get']('user', kafka['user']) %}
{% set user_home = '/home/' + user %}
{% if user == 'root' %}
  {% set user_home = '/' + user %}
{% endif %}

{% if (not product == None) and (not file_path == None) and (not user == None) %}

  {% set skipupdate = salt['file.search'](file_path, 'source ' + user_home + '/.bash_profile\n# Which java to use') %}

  {% if skipupdate == False %}
    {% set config = file_path.split('/')|last %}
configure {{ product }} service:
  file.replace:
    - name: {{ file_path }}
    - pattern: ^# Which java to use.*$
    - repl: source {{user_home}}/.bash_profile\n# Which java to use
    - backup: .bak
  {% endif %}
{% else %}
missing configuration {{product}} abort:
  cmd.run:
    - name: |
        {% for k,v in {'file-path': file_path, 'product': product, 'user': user}.iteritems() %}
        echo {{k}} = {{v}}
        {% endfor %}
  module.run:
    - name: test.false
{% endif %}


