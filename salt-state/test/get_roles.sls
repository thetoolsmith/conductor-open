{% set roles = [] %}
{% set getroles = salt['pillar.get']('config.common:roles') %}

{% for therole in getroles %}
  {% do roles.append(therole) %}
{% endfor %}

{% set ctr = 0 %}

{% for role in roles %}
  {% set ctr = ctr|int + 1 %}
found role {{ role }} in configuration:
  cmd.run:
    - name: |
        echo role found is {{ role }}
{% endfor %}

total roles found in configuration:
  cmd.run:
    - name: |
        echo Total roles found {{ roles|length }}
