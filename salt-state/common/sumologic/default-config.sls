# SALTY SUMOLOGIC -  DICE DEFAULT CONFIG STATE
# MUST PASS AT LEAST service pillar item
# user and group are optional pillar parameters

{% import_yaml "common/sumologic/defaults.yaml" as defaults %}

{% set user = salt['pillar.get']('user', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set group = salt['pillar.get']('group', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set dest_path = salt['pillar.get']('dest-path', defaults.sumologic['dest-path']) %}

create dice sumo credential file on {{grains['id']}} role {{grains['role']}}:
  file.managed:
    - name: {{user}}/sumo_credentials.txt
    - makedirs: True
    - create: True
    - replace: True
    - user: {{user}}
    - group: {{group}}
    - contents: |
        sumo.accessid={{defaults.sumologic['access-id']}}
        sumo.accesskey={{defaults.sumologic['access-key']}}
        collector.name=dice_{{grains['id']}}
        runAs.username={{user}}
        hostName={{grains['id']}}
        timeZone=Etc/UTC
        syncSources={{dest_path}}/dice_sources.json
        sources={{dest_path}}/dice_sources.json

