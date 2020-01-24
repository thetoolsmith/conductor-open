# ORCHESTRATE STATE USED IN TEST3 ORCH REACTOR EVENT TEST
{% set file_name = salt['pillar.get']('file_name', 'unspecified') %}
orch test runner orchestrate reactor:
  salt.function:
    - name: cmd.run
    - tgt: 'saltmaster'
    - arg:
      - mkdir /tmp/foooooobarrrr

