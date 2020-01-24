test text replace single quoted text setup:
  cmd.run:
    - name: |
        echo fooo >>/tmp/foo
        echo cluster_name: \'Test Cluster\' >>/tmp/foo
        echo bla >>/tmp/foo
    - unless: test -f /tmp/foo

{% set role = 'test.this.role' %} 
test text replace single quoted text:
  file.replace:
    - name: /tmp/foo
    - pattern: cluster_name:.*$
    - repl: "cluster_name: '{{role}}_{{grains['id']}}'"
    - backup: .bak

