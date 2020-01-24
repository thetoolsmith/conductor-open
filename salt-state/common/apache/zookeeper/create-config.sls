{% from "common/map.jinja" import common with context %}
{% from "common/apache/zookeeper/map.jinja" import zookeeper with context %}

{% set config = 'zoo.cfg' %}
{% set dest_path = salt['pillar.get']('dest-path', zookeeper['dest-path']) %}
{% set product = salt['pillar.get']('product', zookeeper['product-name']) %}
{% set zoofile = salt['pillar.get']('zoofile', zookeeper['zoofile']) %}
{% set user = salt['pillar.get']('user', zookeeper['user']) %}
{% set group = salt['pillar.get']('group', zookeeper['group']) %}

{% if (not product == None) and (not dest_path == None) and (not user == None) and (not group == None) %}

deploy {{product}} config file:
  file.managed:
    - name: {{ dest_path }}/zookeeper/conf/{{config}}
    - source: {{ zoofile}}
    - makedirs: True
    - replace: True
    - template: jinja
    - onlyif: test -d {{ dest_path }}/zookeeper/conf
    - user: {{user}}
    - group: {{group}}
    - backup: False

    {% if 'cluster.members.info' in grains %}
      {%- for k,v in grains['cluster.members.info'].iteritems() -%}
        {% set _line = "server." + v['member_id']|string + "=" + v['ip']|string + ":2888:3888" %}
update {{config}} with server member {{k}}:
  file.append:
    - name: {{ dest_path }}/zookeeper/conf/{{config}}
    - text: |
        {{ _line }}
    - onlyif: test -f {{ dest_path }}/zookeeper/conf/{{config}}
      {% endfor %}
    {% endif %}

{% else %}

missing configuration {{product}} abort:
  cmd.run:
    - name: |
        {% for k,v in {'dest-path': dest_path, 'product': product, 'user': user, 'group': group}.iteritems() %}
        echo {{k}} = {{v}}
        {% endfor %}
  module.run:
    - name: test.false
{% endif %}
