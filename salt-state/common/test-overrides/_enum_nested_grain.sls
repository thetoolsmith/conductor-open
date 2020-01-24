# GENERIC TEST STATE 
# ENUMERATE NESTED SALT GRAIN

{% set config = 'foo.cfg' %}

test create {{config}} file:
  file.managed:
    - name: /opt/{{config}}
    - source:
    - makedirs: True
    - replace: True
    - onlyif: test -d /opt
    - user: root
    - group: root
    - backup: False




    {% if 'cluster.members.info' in grains %}
      {%- for k,v in grains['cluster.members.info'].iteritems() -%} 
        {% set _line = "server." + v['member_id']|string + "=" + k + ":2888:3888" %} 
update {{config}} with server member {{k}}: 
  file.append:
    - name: /opt/{{config}}
    - text: |
        {{ _line }}
      {% endfor %}
    {% endif %}  

