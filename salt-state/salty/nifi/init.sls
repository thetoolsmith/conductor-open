# ROLE STATE
{% from "common/apache/nifi/map.jinja" import nifi with context %}
{% from "common/map.jinja" import common with context %}
{% from "salty/map.jinja" import pgroup with context %}

{% set role = salt['pillar.get']('role', salt['grains.get']('role', 'salty.nifi')) %}
{% set product = role.split('.')[1] %}
{% set version = salt['pillar.get']('version', salt['pillar.get']('salty.role:' + product + ':product-version', pgroup.nifi['product-version'])) %}
{% set protocol_port = salt['pillar.get']('protocol-port', salt['pillar.get']('salty.role:' + product + ':protocol-port', pgroup.nifi['protocol-port'])) %}
{% set socket_port = salt['pillar.get']('socket-port', salt['pillar.get']('salty.role:' + product + ':socket-port', pgroup.nifi['socket-port'])) %}
{% set sql = salt['pillar.get']('sql', pgroup.nifi['sql']) %}
{% set dsbulk_version = salt['pillar.get']('salty.role:' + product + ':dsbulk-version', pgroup.nifi['dsbulk-version']) %}
{% set dsbulk_source_path = salt['pillar.get']('salty.role:' + product + ':dsbulk-source-path', pgroup.nifi['dsbulk-source-path']) %}

{% set dest_path = None %}
{% if 'dest-path' in pgroup.nifi %}
  {% set dest_path = pgroup.nifi['dest-path'] %}
{% endif %}

{% set env_vars = {} %}

{% if version in salt['pillar.get']('global:apache:nifi:supported-versions', {}) %}

include:
  - common.base

# MOUNT VOLUMES
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
  {% if not salt['pillar.get']('ami-user-map:' + grains['os']) == pgroup.nifi['appuser'] %}
{{role}}_user:
  user.present:
    - name: {{pgroup.nifi['appuser']}}
    - gid: {{pgroup.nifi['appgroup']}}
    - shell: /bin/bash
    - createhome: True
    - require:
      - group: {{role}}_group
{{role}}_group:
  group.present:
    - name: {{pgroup.nifi['appgroup']}}
  {% endif %}

# CALL COMMON ROLE STATE
call common state for {{ role }}: 
  module.run:
    - name: state.sls
    - mods: common.apache.nifi
    - kwargs: {
          pillar: {
  {% if not version == None %}
            version: {{ version }}, 
  {% endif %}
  {% if not pgroup.nifi['java-version'] == None %}
            java-version: {{ pgroup.nifi['java-version'] }}, 
  {% endif %}
  {% if not dest_path == None %}
            dest-path: {{ dest_path }}, 
  {% endif %}
  {% if 'appuser' in pgroup.nifi %}
            user: {{ pgroup.nifi['appuser'] }}, 
  {% endif %}
  {% if 'appgroup' in pgroup.nifi %}
            group: {{ pgroup.nifi['appgroup'] }}, 
  {% endif %}
  {% if not protocol_port == None %}
            protocol-port: {{ protocol_port }}, 
  {% endif %}
  {% if not socket_port == None %}
            socket-port: {{ socket_port }}, 
  {% endif %}
  {% if not sql == None %}
            sql: {{ sql }}, 
  {% endif %} 
            product: nifi
          }   
      }   
    - require:
      - sls: common.base

  # ADD CUSTOM JAVA SYMLINK
  {% if not pgroup.nifi['java-version'] == None %}
create java symlink {{role}}:
    {% set version_dir = '/opt/java/jdk' + pgroup.nifi['java-version'] %}
    {% set java_minor = pgroup.nifi['java-version'].split('.')[1] %}
  cmd.run:
    - name: |
        ln -s {{ version_dir }}/ /opt/java{{java_minor}}
    - unless:
      - ls /opt/java{{java_minor}}
update nifi-env file for {{role}}:
  file.replace:
    - name: {{pgroup.nifi['home']}}/bin/nifi-env.sh
    - pattern: ^#export JAVA_HOME=.*$
    - repl: export JAVA_HOME=/opt/java{{pgroup.nifi['java-version'].split('.')[1]}}
    - backup: .bak
  {% endif %}

  # SET OWNER ON DEST PATH (SHOULD BE MOUNTED VOLUME)
  {% if not dest_path == None %} 
set owner for {{ pgroup.nifi['home'] }} for {{role}}:
  file.directory:
    - name: {{ pgroup.nifi['home'] }}
    - user: {{pgroup.nifi['appuser']}}
    - group: {{pgroup.nifi['appgroup']}}
    - recurse:
      - user
      - group
  {% endif %}

  # CONFIGURE LINKS TO NIFI REPOS AND SET OWNERSHIP
  {% set repos = nifi['repos'] %}
  {% for repo in repos %}
    {% do env_vars.update({'NIFI_' + repo[:-6]|replace('database', 'DB')|upper: pgroup.nifi['home'] + '/nifi_' + repo}) %}
    {% if not salt['file.directory_exists' ](pgroup.nifi['home'] + '/' + repo) %}
create link for {{repo}} for salty.nifi:
  file.symlink:
    - name: {{pgroup.nifi['home']}}/{{repo}}
    - target: /nifi_{{repo}}/{{version}}/{{repo}}
    - user: {{pgroup.nifi['appuser']}}
    - group: {{pgroup.nifi['appgroup']}}
    - unless: test -d {{pgroup.nifi['home']}}/{{repo}}
    {% endif %}
  {% endfor %}

  # INSTALL DSBULK
  {% if not dsbulk_version == None %}
create dsbulk directory for {{role}}:
  file.directory:
    - name: {{ dest_path }}/dsbulk
    - makedirs: True
    - user: {{ pgroup.nifi['appuser'] }}
    - group: {{ pgroup.nifi['appgroup'] }}
    - mode: 755
fetch dsbulk for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}/dsbulk
    - name: |
        curl {{dsbulk_source_path}}/dsbulk-{{dsbulk_version}}.tar.gz -o dsbulk-{{dsbulk_version}}.tar.gz
        tar -xvf dsbulk-{{dsbulk_version}}.tar.gz
  {% endif %}

  # APPLY SET LOCAL ENVIRONMENT STATE
apply local environment state for {{role}}:    
  module.run:
    - name: state.sls
    - mods: salty.nifi.set-environment
    - kwargs: {
          pillar: {
            env-vars: {{ env_vars }}
          }   
      }

  # FETCH NAR FLOW FILES
  {% if 'nar' in pgroup.nifi and 'flow' in pgroup.nifi['nar'] %}
    {% for nf, nfp in pgroup.nifi['nar']['flow']['files'].iteritems() %}
fetch {{nf}} for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{pgroup.nifi['home']}}/lib
    - name: |
        curl {{common.artifactory.connector}}{{pgroup.nifi['nar']['flow']['location']}}{{nfp}}/{{nf}} -o {{nf}}
    {% endfor %}
  {% endif %}

  # FETCH NAR OTHER FILES
  {% if 'nar' in pgroup.nifi and 'other' in pgroup.nifi['nar'] %}
    {% for nf, nfp in pgroup.nifi['nar']['other']['files'].iteritems() %}
fetch {{nf}} for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{pgroup.nifi['home']}}/lib
    - name: |
        curl {{common.artifactory.connector }}{{pgroup.nifi['nar']['other']['location']}}{{nfp}}/{{nf}} -o {{nf}}
    {% endfor %}
  {% endif %}

  # SET OWNER ON NARS
  {% if not dest_path == None %} 
set owner NARS for {{role}}:
  file.directory:
    - name: {{ pgroup.nifi['home'] }}/lib
    - user: {{pgroup.nifi['appuser']}}
    - group: {{pgroup.nifi['appgroup']}}
    - recurse:
      - user
      - group
    - onlyif: test -d {{ pgroup.nifi['home'] }}/lib
  {% endif %}

  # UPDATE state-management.xml
update state-management file for {{role}}:    
  module.run:
    - name: state.sls
    - mods: salty.nifi.update-state-management
    - kwargs: {
          pillar: {
            file-path: {{pgroup.nifi['home']}}/conf/state-management.xml
          }   
      }
    - onlyif: test -f {{pgroup.nifi['home']}}/conf/state-management.xml

  # UPDATE nifi.properties
update nifi.properties file for {{role}}:    
  module.run:
    - name: state.sls
    - mods: salty.nifi.update-nifi-properties
    - kwargs: {
          pillar: {
            file-path: {{pgroup.nifi['home']}}/conf/nifi.properties
          }   
      }
    - onlyif: test -f {{pgroup.nifi['home']}}/conf/nifi.properties

   # UPDATE bootstrap.conf
update bootstrap.conf file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.nifi.update-bootstrap-conf
    - kwargs: {
          pillar: {
            file-path: {{pgroup.nifi['home']}}/conf/bootstrap.conf
          }
      }
    - onlyif: test -f {{pgroup.nifi['home']}}/conf/bootstrap.conf

   # UPDATE logback.xml
update logback.xml file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.nifi.update-logback
    - kwargs: {
          pillar: {
            file-path: {{pgroup.nifi['home']}}/conf/logback.xml
          }
      }
    - onlyif: test -f {{pgroup.nifi['home']}}/conf/logback.xml

   # UPDATE nproc.conf
update nproc.conf file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.nifi.update-nproc-conf
    - kwargs: {
          pillar: {
            file-path: /etc/security/limits.d/20-nproc.conf
          }
      }
    - onlyif: test -f /etc/security/limits.d/20-nproc.conf

  # UPDATE AND INSTALL SERVICE
update and install {{role}} {{version}} service config:
  module.run:
    - name: state.sls
    - mods: common.apache.nifi.install-service
    - kwargs: {
          pillar: {
            file-path: {{ pgroup.nifi['home'] }}/bin, 
            user: {{ pgroup.nifi['appuser'] }}
          }   
      }
    - onlyif: test -d {{ pgroup.nifi['home'] }}/bin

  # FIRE EVENT TO CREATE ZNODE
fire event {{role}} {{version}} create-znode:
  {% set znode = 'nifi' + grains[grains['role'] + '.cluster.id']|string %}
  module.run:
    - name: state.sls
    - mods: common.apache.zookeeper.event.create-znode
    - kwargs: {
          pillar: {
            znode: {{znode}} {{znode}}/data,
            zoo-bin: {{pgroup.zookeeper['dest-path']}}/zookeeper/bin/zkCli.sh
          }
      }

  # START SERVICE (LAST TASK)
start {{role}} nifi service:
  cmd.run:
    - name: |
        service nifi start
    - bg: True
status {{role}} nifi service:
  cmd.run:
    - name: |
        sleep 20
        service nifi status

  # APPLY MONITORING STATES
monitoring for {{role}} on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.monitoring
    - kwargs: {
          pillar: {
    {% if 'appuser' in pgroup.nifi %}
            user: {{pgroup.nifi['appuser']}},
    {% endif %}
            service: nifi
          }
      }

{% else %}
# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
