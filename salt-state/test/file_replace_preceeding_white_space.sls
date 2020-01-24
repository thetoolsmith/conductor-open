test replace with preceeding white space text setup:
  cmd.run:
    - name: |
        echo fooo >>/tmp/foo
        echo cluster_name: \'Test Cluster\' >>/tmp/foo
        echo bla >>/tmp/foo
    - unless: test -f /tmp/foo

{% set role = 'test.this.role' %}

test replace with preceeding white space text:
  file.replace:
    - name: /tmp/foo
    - pattern: '            store_type:.*$'
    - repl: '            store_type: REPLACED'
    - append_if_not_found: True
    - backup: .bak

