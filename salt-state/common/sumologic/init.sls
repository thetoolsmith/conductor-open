# SUMOLOGIC - COMMON STATE
# DYNAMIC PILLAR OPTIONS 
# user
# group
# dest-path
# basecfg True|False (if creating config at the product group role level, keep this False)

{% import_yaml "common/sumologic/defaults.yaml" as defaults %}

{% set user = salt['pillar.get']('user', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set group = salt['pillar.get']('group', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set dest_path = salt['pillar.get']('dest-path', defaults.sumologic['dest-path']) %}
{% set base_config = salt['pillar.get']('basecfg', False) %}

create sumo download dir on {{grains['id']}} role {{grains['role']}}:
  file.directory:
    - name: /home/{{user}}/sumo
    - user: {{user}}
    - group: {{group}}
    - makedirs: True
    - mode: 755

install sumologic agent on {{grains['id']}} role {{grains['role']}}:
  cmd.run:
    - name: |
        wget "https://collectors.sumologic.com/rest/download/linux/64" -O SumoCollector.sh
        chmod +x SumoCollector.sh
    - cwd: /home/{{user}}/sumo

create {{dest_path}} on {{grains['id']}} role {{grains['role']}}:
  file.directory:
    - name: {{dest_path}}
    - user: {{ user }}
    - group: {{ group }}
    - makedirs: True
    - mode: 755

{% if base_config == True %}
apply sumo logic base config on {{grains['id']}} role {{grains['role']}}:
  module.run:
    - name: state.sls
    - mods: common.sumologic.base
    - kwargs: { 
          pillar: {
            user: {{user}},
            group: {{group}},
            dest-path: {{dest_path}}
          }    
      }    
{% endif %}

