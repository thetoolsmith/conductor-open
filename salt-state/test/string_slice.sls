{% set fname = 'kafka_2.11-2.0.0.tgz' %}
test string slicing in jinja:
  cmd.run:
    - name: |
        mv {{fname[:5]}}* kafka
    - cwd: /datalake
