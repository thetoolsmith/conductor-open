# SALTY SUMOLOGIC - GENERIC SERVICE CONFIG STATE
# MUST PASS AT LEAST service pillar item
# ASSUMES SumoCollector.sh is in /home/USER
# user and group are optional pillar parameters

{% import_yaml "common/sumologic/defaults.yaml" as defaults %}

{% set user = salt['pillar.get']('user', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set group = salt['pillar.get']('group', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set service = salt['pillar.get']('service', None) %}
{% set dest_path = salt['pillar.get']('dest-path', defaults.sumologic['dest-path']) %}

{% if not service == None %}

create sumo cedential file on {{grains['id']}} role {{grains['role']}}:
  file.managed:
    - name: {{dest_path}}/sumo_credentials.txt
    - makedirs: True
    - create: True
    - replace: True
    - user: {{user}}
    - group: {{group}}
    - contents: |
        sumo.accessid={{defaults.sumologic['access-id']}}
        sumo.accesskey={{defaults.sumologic['access-key']}}
        collector.name={{service}}_{{grains['ipv4'][0]}}
        runAs.username={{user}}
        hostName={{grains['ipv4'][0]}}
        timeZone=Etc/UTC
        syncSources={{dest_path}}/{{service}}_sources.json
        sources={{dest_path}}/{{service}}_sources.json

deploy {{service}}_sources.json on {{grains['id']}} role {{grains['role']}}:
  file.managed:
    - name: {{dest_path}}/{{service}}_sources.json
    - source: salt://common/sumologic/templates/_sources.json
    - makdirs: True
    - replace: True
    - user: {{user}}
    - group: {{group}}
    - backup: .bak

replace __NAME__ in {{dest_path}}/{{service}}_sources.json on {{grains['id']}} role {{grains['role']}}:
  file.replace:
    - name: {{dest_path}}/{{service}}_sources.json
    - pattern: __NAME__
    - repl: {{service}}_logs
    - onlyif: test -f {{dest_path}}/{{service}}_sources.json

replace __EXPR_PATH__ in {{dest_path}}/{{service}}_sources.json on {{grains['id']}} role {{grains['role']}}:
  file.replace:
    - name: {{dest_path}}/{{service}}_sources.json
    - pattern: __EXPR_PATH__
    - repl: /datalake/{{service}}/logs/*
    - onlyif: test -f {{dest_path}}/{{service}}_sources.json

replace __CATEGORY__ in {{dest_path}}/{{service}}_sources.json on {{grains['id']}} role {{grains['role']}}:
  file.replace:
    - name: {{dest_path}}/{{service}}_sources.json
    - pattern: __CATEGORY__
    - repl: {{grains['pillar.environment']}}/datalake/{{service}}
    - onlyif: test -f {{dest_path}}/{{service}}_sources.json

{% endif %}
