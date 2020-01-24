{% set role = salt['pillar.get']('role', 'salty.cassandra') %}
test {{role}} cassandra_user:
  user.present:
    - name: cassandra
    - gid: foobar
    - shell: /bin/bash
    - createhome: True
    - require:
      - group: test {{role}} cassandra_group

test {{role}} cassandra_group:
  group.present:
    - name: foobar

