{% set _seeds = grains['zookeeper.hostname']|join(',') %}
{% set newstring = '"' + _seeds + '"' %}

test create list_to_str:
  file.touch:
    - name: /tmp/list_to_str
    - unless: test -f /tmp/list_to_str

test jinja list_to_string:
  file.append:
    - name: /tmp/list_to_str
    - text: |
        new text..... {{ newstring }}
    - onlyif: test -f /tmp/list_to_str


