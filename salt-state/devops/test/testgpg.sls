{% set foo = salt['pillar.get']('us-east-1:key') %}
message one testing gpg decrypt:
  cmd.run:
    - names:
      - echo value is {{ foo }}
