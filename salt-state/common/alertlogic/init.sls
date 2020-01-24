# ALERTLOGIC - COMMON STATE
# INSTALLS ALERTLOGIC AGENT AND SETS TO STOPPED
# START SERVICE AS NEEDED PER PRODUCT AND ENVIRONMENT
# DYNAMIC PILLAR OPTIONS:
# version 
# user
{% from "common/map.jinja" import common with context %}

{% import_yaml "common/alertlogic/defaults.yaml" as defaults %}
{% set agent = defaults.alertlogic.agent %}
{% set version = salt['pillar.get']('version', agent['product-version']) %}
{% set user = salt['pillar.get']('user', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}

{% if not agent['key'] == 'unspecified' %}
  {% if (version in salt['pillar.get']('global:alertlogic:agent:supported-versions')) and (not agent['srcpath'] == None) %}
    {% set package = salt['pillar.get']('global:alertlogic:agent:supported-versions:' + version + ':package', None) %}
    {% set uri = 'https://' + common.artifactory.user + ':' + common.artifactory.token + '@' + common.artifactory.host + agent['srcpath'] + package %}

fetch and install alertlogic agent for {{grains['id']}} role {{grains['role']}}:
  cmd.run:
    - name: |
        curl {{ uri }} -o {{ package }}
        semanage port -a -t syslogd_port_t -p tcp {{agent['port']}}
        rpm -ivhU {{package}}
        /etc/init.d/al-agent provision --key {{agent['key']}}
        yum history sync
        echo Installing alertlogic complete
        echo Stopping service.....
        /etc/init.d/al-agent stop
    - cwd: /home/{{user}}
  {% endif %}
{% endif %}
