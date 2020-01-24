# test state
{% set target_minion = salt['pillar.get']('target-minion', '*') %}
test.ping state:
  module.run:
    - name: test.ping
    - tgt: '{{ target_minion }}'
