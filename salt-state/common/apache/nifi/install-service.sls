{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

{% set file_path = salt['pillar.get']('file-path', None) %}
{% set product = salt['pillar.get']('product', nifi['product-name']) %}
{% set user = salt['pillar.get']('user', nifi['user']) %}
{% set user_home = '/home/' + user %}
{% if user == 'root' %}
  {% set user_home = '/' + user %}
{% endif %}

{% if (not product == None) and (not file_path == None) and (not user == None) %}

  {% set skipupdate = salt['file.search'](file_path + '/nifi.sh', 'source ' + user_home + '/.bash_profile\n# Discover the path of the file') %}

  {% if skipupdate == False %}
    {% set config = 'nifi.sh' %}

configure {{ product }} service:
  file.replace:
    - name: {{ file_path }}/{{ config }}
    - pattern: ^# Discover the path of the file.*$
    - repl: 'source {{user_home}}/.bash_profile\nJAVA="${JAVA}"\n# Discover the path of the file'
    - backup: .bak
  {% endif %}

install {{product}} service:
  cmd.run: 
    - name: |
        {{ file_path }}/{{ config }} install

{% else %}
missing configuration {{product}} abort:
  {% set args = {'file-path': file_path, 'product': product, 'user': user} %}
  cmd.run:
    - name: |
        {% for k,v in args.iteritems() %}
        echo {{k}} = {{v}}
        {% endfor %}
  module.run:
    - name: test.false
{% endif %}


