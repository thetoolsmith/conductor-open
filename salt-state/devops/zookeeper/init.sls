# ROLE STATE
{% import_yaml "devops/zookeeper/defaults.yaml" as defaults %}

{% set version = salt['pillar.get']('version', salt['pillar.get']('devops.role:zookeeper:product-version', defaults.zookeeper['product-version'])) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('devops.role:zookeeper:java:version', defaults.zookeeper['java-version'])) %}
{% set role = 'devops.zookeeper' %}

{% if version in salt['pillar.get']('global:apache:zookeeper:supported-versions', {}) %}

include:
  - common.base

call common state for {{ role }}: 
  module.run:
    - name: state.sls
    - mods: common.apache.zookeeper
    - kwargs: {
          pillar: {
{% if not version == None %}
            version: {{ version }},
{% endif %}
{% if not java_version == None %}
            java-version: {{ java_version }},
{% endif %}
{% if 'dest-path' in defaults.zookeeper %}
            dest-path: {{ defaults.zookeeper['dest-path'] }},
{% endif %}
{% if 'user' in defaults.zookeeper %}
            user: {{ defaults.zookeeper['user'] }},
{% endif %}
{% if 'group' in defaults.zookeeper %}
            group: {{ defaults.zookeeper['group'] }},
{% endif %}
{% if 'zoofile' in defaults.zookeeper %}
            zoofile: '{{ defaults.zookeeper["zoofile"] }}',
{% endif %}
            product: zookeeper
          }   
      }   
    - require:
      - sls: common.base

mount volumes for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }
      }
{% else %}
# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
