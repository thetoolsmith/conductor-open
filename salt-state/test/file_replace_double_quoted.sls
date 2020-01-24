test text replace single quoted text setup:
  cmd.run:
    - name: |
        echo fooo >>/tmp/foo
        echo cluster_name: \'Test Cluster\' >>/tmp/foo
        echo bla >>/tmp/foo
    - unless: test -f /tmp/foo

{% set role = 'test.this.role' %}
{% set replstring = '"' + grains['ipv4'][0] + '"' %}

test text replace single quoted text:
  file.replace:
    - name: /tmp/foo
    - pattern: '- seeds: "127.0.0.1".*$'
    - repl: '- seeds: {{replstring}}'
    - append_if_not_found: True
    - backup: .bak

