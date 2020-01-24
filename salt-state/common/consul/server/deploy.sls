# COMMON CONSUL-SERVER STATE
{% from "common/map.jinja" import common with context %}

{% set product = common.consul.server['product-name'] %}
{% set role = salt['pillar.get']('role', None) %} #role passed in pillar such as role=devops.rabbitmq
{% if role == None %}
  {% set role = product %}
{% endif %}
{% set version = salt['pillar.get']('version', common.consul.server['product-version']) %}
{% if version == None %}
exception_no_version_{{product}}:
  module.run:
    - name: test.exception
    - message: version not found in defaults or pillar for {{product}}
{% endif %}

{% set supportedversions = salt['pillar.get']('global:consul:server:supported-versions', {}) %}
{% for k,v in supportedversions.iteritems() %}
  {% if version == k %}
    # TODO: need to check the md5 hash value as well
    {% set thepackage = v['package'] %}
    {% set uri = 'https://' + common.artifactory.user + ':' + common.artifactory.token + '@' + common.artifactory.host + common.consul.server.srcpath + version + '/' + thepackage %}
    {% set skipupdate = salt['file.search']('/etc/apt/sources.list', 'libs.orgx.net') %}

create deploy directory for {{ role }}:
  cmd.run:
    - names:
      - mkdir -p /opt/deploy

get aptkey for {{ role }}:
  cmd.run:
    - cwd: /opt/deploy
    - names:
      - wget http://{{ common.artifactory.host }}/api/gpg/key/public
      - apt-key add public

    {% if skipupdate == False %}
update sources {{ role }}:
  file.append:
    - name: /etc/apt/sources.list
    - text: |
        deb https://{{common.artifactory.user}}:{{common.artifactory.token}}@{{common.artifactory.host}}/orgX/debian trusty main
    {% endif %}

update local apt store{{ role }}:
  cmd.run:
    - names:
      - apt-get update

install {{ role }} package:
  cmd.run:
    - cwd: /opt/deploy
    - names:
      - apt-get install -y -q {{ common.consul.server['product-name'] }}={{ common.consul.server['product-version'] }}
      - rm -rf /opt/deploy/*

assure {{ role }} service is stopped:
  service.dead:
    - names:
      - consul-server

create local {{ role }} config path:
  cmd.run:
    - names:
      - mkdir -p {{ common.consul.server['config-location'] }}

generate local {{ role }} config:
  module.run:
    - name: ext_consul.create_{{role}}_server_config
    - config: {{ common.consul.server['config-location'] }}
    - env: {{ env }}

generate local {{ role }} watch config:
  module.run:
    - name: ext_consul.create_{{role}}_server_watch_config
    - config: {{ common.consul.server['config-location'] }}

deploy local {{role}} config:
  file.managed:
    - name: /usr/share/consul/server/config/config.json
    - source: salt://common/consul/server/files/config.json
    - makedirs: true
    - user: root
    - group: root
    - mode: 0644
    - template: jinja

startup {{ product }} service:
  service.running:
    - names:
      - consul-server

  {% else %}
failed to find supported version for {{role}}:
  cmd.run:
    - names:
      - echo FAILED TO FIND SUPPORTED VERSION FOR {{role}}
  {% endif %}
{% endfor %}
