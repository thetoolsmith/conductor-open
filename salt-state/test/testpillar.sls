
{% set foo = salt['pillar.get']('global:default-startup') %}

message one testing pillar env:
  cmd.run:
    - names:
      - echo test result -- {{ foo }}



