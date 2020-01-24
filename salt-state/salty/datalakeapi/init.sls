# ROLE STATE
{% from "common/map.jinja" import common with context %}
{% import_yaml "salty/datalakeapi/defaults.yaml" as defaults %}
{% set role = salt['pillar.get']('role', salt['grains.get']('role', 'salty.datalakeapi')) %}
{% set product = role.split('.')[1] %}
{% set version = salt['pillar.get']('version', defaults.datalakeapi['product-version']) %}
{% set java_version = salt['pillar.get']('salty.role:datalakeapi:java-version', defaults.datalakeapi['java-version']) %}
{% set dest_path = salt['pillar.get']('dest-path', defaults.datalakeapi['dest-path']) %}
{% set package = salt['pillar.get']('salty.role:datalakeapi:package', product + '-' + version + '.tgz') %}

# CHECKS GROUP ROLE PILLAR FIRST, THEN DEFAULTS TO CONFIG.COMMON PILLAR, OR FALSE
{% set enable_alertlogic = salt['pillar.get']('salty.role:enable-alertlogic', salt['pillar.get']('config.common:alertlogic:enabled', False)) %}
{% set enable_sumologic = salt['pillar.get']('salty.role:enable-sumologic', salt['pillar.get']('config.common:sumologic:enabled', False)) %}
{% set enable_datadog = salt['pillar.get']('salty.role:enable-datadog', salt['pillar.get']('config.common:datadog:enabled', False)) %}

include:
  - common.base
{% if not enable_datadog == False %}
  - common.datadog
{% endif %}
{% if not enable_sumologic == False %}
  - common.sumologic
{% endif %}
{% if not enable_alertlogic == False %}
  - common.alertlogic
{% endif %}

mount volumes for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }
      }

#INSTALL JAVA
install jdk {{java_version}} for {{product}} on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: common.oracle.jdk
      {% if not java_version == None %}
    - kwargs: {
          pillar: {
            version: {{java_version}},
            user: {{defaults.datalakeapi['user']}}
          }   
      }   
      {% endif %}

create {{dest_path}} on {{grains['id']}}:
  file.directory:
    - name: {{ dest_path }}
    - makedirs: True
    - user: {{defaults.datalakeapi['appuser']}}
    - group: {{defaults.datalakeapi['appgroup']}}
    - mode: 755 

create /datalake_logdir/{{product}} on {{grains['id']}}:
  file.directory:
    - name: /datalake_logdir/{{product}}
    - makedirs: True
    - user: {{defaults.datalakeapi['appuser']}}
    - group: {{defaults.datalakeapi['appgroup']}}
    - mode: 755 

fetch {{product}} for {{grains['id']}}:
  cmd.run:
    - output_loglevel: quiet
    - cwd: {{ dest_path }}
    - name: |
        curl {{common.artifactory.connector }}{{defaults.datalakeapi['srcpath']}}/{{version}}/{{package}} -o {{dest_path}}/{{package}}
        tar zxf {{package}} -C {{dest_path}}
        mv {{product}}-{{version}} {{product}}
        rm -rf {{package}}
        chown -hR {{defaults.datalakeapi['appuser']}}:{{defaults.datalakeapi['appgroup']}} {{dest_path}}/{{product}}
        chmod +x {{dest_path}}/{{product}}/bin/{{product}}
    
/etc/systemd/system/datalake_rest_api_ssl.service:
  file.managed:
    - source: salt://salty/datalakeapi/templates/datalake_rest_api_ssl.service
    - user: {{defaults.datalakeapi['user']}}
    - group: {{defaults.datalakeapi['group']}}

/etc/systemd/system/datalake_rest_api_no_ssl.service:
  file.managed:
    - source: salt://salty/datalakeapi/templates/datalake_rest_api_no_ssl.service
    - user: {{defaults.datalakeapi['user']}}
    - group: {{defaults.datalakeapi['group']}}

set truststore /etc/systemd/system/datalake_rest_api_ssl.service:
{% set trust_pass = salt['pillar.get']('salty.role:javax.net.ssl.trustStorePassword', 'unspecified') %} 
  file.replace:
    - name: /etc/systemd/system/datalake_rest_api_ssl.service
    - pattern: __TRUSTSTORE_PASSWORD__
    - repl: {{trust_pass}}
    - backup: .bak

set keystore /etc/systemd/system/datalake_rest_api_ssl.service:
{% set key_pass = salt['pillar.get']('salty.role:javax.net.ssl.keyStorePassword', 'unspecified') %} 
  file.replace:
    - name: /etc/systemd/system/datalake_rest_api_ssl.service
    - pattern: __KEYSTORE_PASSWORD__
    - repl: {{key_pass}}
    - backup: .bak

reload service daemon on {{grains['id']}}:
  cmd.run:
    - name: |
        systemctl daemon-reload

set local environment {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.datalakeapi.set-environment

# CONFIGURE DATADOG IF ENABLED
{% if not enable_datadog == False %}
configure datadog on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.datadog.set-environment
    - kwargs: {
          pillar: {
            user: {{defaults.datalakeapi['user']}}
          }
      }
{% endif %}

# CONFIGURE SUMOLOGIC IF ENABLED
{% if not enable_sumologic == False %}
configure sumologic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.sumologic.base-config
    - kwargs: {
          pillar: {
            service: {{product}}
          }
      }
# INIT SUMOLOGIC COLLECTOR
initialize sumologic collector on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: salty.sumologic.init-collector
{% endif %}

# START ALERT LOGIC IF ENABLED
{% if not enable_alertlogic == False %}
start alertlogic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: service.restart
    - m_name: al-agent

status alertlogic on {{grains['id']}} for {{grains['role']}}:
  module.run:
    - name: service.status
    - m_name: al-agent
{% endif %}


# DEPLOY SECURITY STUFF.... TBD




