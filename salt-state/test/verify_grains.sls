{% set role = 'salty.nifi' %}
{% set _var = None %}
{% if (grains['role']|lower == role) or
        ((not iscomposite == None) and (role in grains['composite.role']) ) %}

  {% set _var = grains['cluster.members'] %}

show cluster grains {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - name: |
        echo {{grains['cluster.members']}}

  {% if  _var is iterable and var is not string %}

{{role}} has correct grain type:
  cmd.run:
    - name: |
        echo cluster.members is a List

  {% endif %}

{% endif %}
