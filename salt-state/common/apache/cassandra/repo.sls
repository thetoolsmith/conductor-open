{% import_yaml "common/apache/cassandra/version.yaml" as default %}
{% set version_short = '300' %}

{% if 'version' in default %}
  {% set version_short = default['version'].split('.')[0] + default['version'].split('.')[1] %}
{% endif %}

/etc/yum.repos.d/cassandra.repo:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - attrs: ai
    - mkdirs: True
    - replace: True
    - template: jinja
{% if grains['os'] == 'CentOS' %}
    - contents: |
        [cassandra]
        name=Apache Cassandra
        baseurl=https://www.apache.org/dist/cassandra/redhat/{{version_short}}x/
        gpgcheck=1
        repo_gpgcheck=1
        gpgkey=https://www.apache.org/dist/cassandra/KEYS
{% endif %}

