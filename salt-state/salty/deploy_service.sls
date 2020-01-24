{% from "salty/map.jinja" import pgroup with context %}

{% set svc = salt['pillar.get']('svc', 'unspecified') %}

{% if not svc == 'unspecified' %} 
  {% set user = pgroup[svc]['appuser'] %}
  {% set group = pgroup[svc]['appgroup'] %}
  {% set dest_path = pgroup[svc]['dest-path'] %}
  # DEPLOY SERVICE TEMPLATE
/etc/systemd/system/{{svc}}.service:
  file.managed:
    - source: salt://salty/templates/{{svc}}.service
    - user: {{user}}
    - group: {{group}}
    - template: jinja

reload {{svc}} daemon on {{grains['id']}}:
  cmd.run:
    - name: |
        chown -R {{user}}:{{group}} {{dest_path}}
        systemctl daemon-reload
        systemctl enable {{svc}}

  # APPLY SET LOCAL ENVIRONMENT STATE
configure local environment for {{svc}} on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.{{svc}}.set-environment
{% endif %}
