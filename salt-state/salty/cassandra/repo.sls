# CUSTOM IMPLEMENTATION REPO STATE TO PASS INTO common.apachae.cassandra
{% set dse_user = salt['pillar.get']('salty.role:cassandra:dse_user', None) %}
{% set dse_password = salt['pillar.get']('salty.role:cassandra:dse_password', None) %}

/etc/yum.repos.d/{{grains['product.group']}}_datastax.repo:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - attrs: ai
    - mkdirs: True
    - replace: True
    - template: jinja
    - contents: |
        [datastax]
        name=DataStax Repository
        baseurl=https://{{dse_user}}:{{dse_password}}@rpm.datastax.com/enterprise
        enabled=1
        gpgcheck=0
        [opscenter]
        name=DataStax Repository
        baseurl=https://{{dse_user}}:{{dse_password}}@rpm.datastax.com/enterprise
        enabled=1
        gpgcheck=0

