{% set var1 = [1,2,3] %}
{% set var2 = 1 %}
{% set var3 = "1,2,3" %}

{% if var1 is iterable and var is not string %}
answer one:
  cmd.run:
    - name: |
        echo var1 is a list
{% endif %}

{% if not var2 is iterable and var2 is not string %}
answer one A:
  cmd.run:
    - name: |
        echo var2 is really a number
{% endif %}

{% if var2 is iterable and var2 is not string %}
answer two:
  cmd.run:
    - name: |
        echo var2 is a list
{% else %}
answer three:
  cmd.run:
    - name: |
        echo var2 is int
{% endif %}

{% if var3 is iterable and var3 is string %}
answer four:
  cmd.run:
    - name: |
        echo var3 is a string
{% endif %}

