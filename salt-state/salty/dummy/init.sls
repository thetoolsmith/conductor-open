# TEST SALT STATE

{% set version = salt['pillar.get']('version', '9.9.9') %}

salty product group dummy role:
  cmd.run:
    - name: |
        echo this is salt dummy role version {{version}}
        echo it does nothing
