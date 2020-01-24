{% set role = 'nifi' %}
{% set role_config = 'salty.role:' + role %}

{% if salt['pillar.get'](role_config + ':dependencies') %}
  {% set _depends = salt['pillar.get'](role_config, {})['dependencies'] %}

  {% if _depends != None %}
    {% for d,v in _depends.iteritems() %}

found dependency {{ d }}: 
  cmd.run:
    - names:
      - echo DEPENDENCY {{ d }} {{ v }}

    {% endfor %}
  {% endif %}
{% endif %}
