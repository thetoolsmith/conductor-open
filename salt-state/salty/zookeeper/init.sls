# ROLE STATE
{% from "salty/map.jinja" import pgroup with context %}

{% set role = salt['pillar.get']('role', salt['grains.get']('role', 'salty.zookeeper')) %}
{% set product = role.split('.')[1] %}
{% set version = salt['pillar.get']('version', pgroup.zookeeper['version']) %}
{% set java_version = salt['pillar.get']('java-version', salt['pillar.get']('salty.role:' + product + ':java:version', pgroup.zookeeper['java-version'])) %}

{% set env_vars = {} %}

{% if version in salt['pillar.get']('global:apache:zookeeper:supported-versions', {}) %}

include:
  - common.base

mount volumes for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }
      }

  # CREATE LOCAL APPUSER IF NOT DEFAULT CLOUD USER 
  {% if not salt['pillar.get']('ami-user-map:' + grains['os']) == pgroup.zookeeper['appuser'] %}
{{role}}_user:
  user.present:
    - name: {{pgroup.zookeeper['appuser']}}
    - gid: {{pgroup.zookeeper['appgroup']}}
    - shell: /bin/bash
    - createhome: True
    - require:
      - group: {{role}}_group
{{role}}_group:
  group.present:
    - name: {{pgroup.zookeeper['appgroup']}}
  {% endif %}

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
{% if 'dest-path' in pgroup.zookeeper %}
            dest-path: {{ pgroup.zookeeper['dest-path'] }},
{% endif %}
{% if 'appuser' in pgroup.zookeeper %}
            user: {{ pgroup.zookeeper['appuser'] }},
{% endif %}
{% if 'appgroup' in pgroup.zookeeper %}
            group: {{ pgroup.zookeeper['appgroup'] }},
{% endif %}
{% if 'zoofile' in pgroup.zookeeper %}
            zoofile: '{{ pgroup.zookeeper["zoofile"] }}',
{% endif %}
            product: zookeeper
          }   
      }   
    - require:
      - sls: common.base

  # ADD CUSTOM JAVA SYMLINK
  {% if not java_version == None %}
create java symlink {{role}}:
    {% set version_dir = '/opt/java/jdk' + java_version %}
    {% set java_minor = java_version.split('.')[1] %}
  cmd.run:
    - name: |
        ln -s {{ version_dir }}/ /opt/java{{java_minor}}
    - unless:
      - ls /opt/java{{java_minor}}
  {% endif %}

  # CREATE DATADIR
/datalake_datadir/{{pgroup.zookeeper['product-version']}}/data:
  file.directory:
    - makedirs: True
    - user: {{pgroup.zookeeper['appuser']}}
    - group: {{pgroup.zookeeper['appgroup']}}
    - dir_mode: 755
    - file_mode: 744
    - recurse:
      - user
      - group
      - mode

  # CREATE LOGDIR
/datalake_logdir/{{pgroup.zookeeper['product-version']}}/logs:
  file.directory:
    - makedirs: True
    - user: {{pgroup.zookeeper['appuser']}}
    - group: {{pgroup.zookeeper['appgroup']}}
    - dir_mode: 755
    - file_mode: 744
    - recurse:
      - user
      - group
      - mode

  # CREATE CUSTOM SYMLINKS
create {{grains['role']}} symlinks on {{grains['id']}}:
  cmd.run:
    - name: |
        ln -s /datalake_datadir/{{pgroup.zookeeper['product-version']}}/data {{pgroup.zookeeper['dest-path']}}/zookeeper/data
        ln -s /datalake_logdir/{{pgroup.zookeeper['product-version']}}/logs {{pgroup.zookeeper['dest-path']}}/zookeeper/logs

  # DEPLOY SVC STATE AND SET ENV
deploy {{role}} service on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.deploy_service
    - kwargs: {
          pillar: {
            svc: zookeeper
          }
      }

  # MOVE myid FILE
place id file on {{grains['id']}}:
  cmd.run:
    - name: |
        cp {{pgroup.zookeeper['dest-path']}}/myid {{pgroup.zookeeper['dest-path']}}/zookeeper/data

  # APPLY MONITORING STATES
monitoring for {{role}} on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.monitoring
    - kwargs: {
          pillar: {
    {% if 'appuser' in pgroup.zookeeper %}
            user: {{pgroup.zookeeper['appuser']}},
    {% endif %}
            service: zookeeper
          }
      }

  # START ZOOKEEPER
start zookeeper on {{grains['id']}}:
  module.run:
    - name: service.start
    - m_name: zookeeper

{% else %}
# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
