# CUSTOM IMPLEMENTATION REPO STATE 
# WE COULD JUST USE THE STATE COMMON/DATASTAX IF ALL PRODUCT GROUPS
# WILL BE USING THE SAME DSE USER AND PASSWORD. TBD!!
{% set dse_user = salt['pillar.get']('config.common:datastax:dse_user', None) %}
{% set dse_password = salt['pillar.get']('config.common:datastax:dse_password', None) %}

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
