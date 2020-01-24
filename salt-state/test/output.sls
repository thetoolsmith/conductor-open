# OUTPUT TESTER
{% from "common/map.jinja" import common with context %}
{% set sql = '/artifactory/orgX/vetted/mysql/mysql-connector-java-5.1.45-bin.jar' %}
{% if not sql == None %}  
output tester:
  cmd.run:
    - output_loglevel: quiet
    - name: |
        curl {{common.artifactory.connector}}{{sql}} -o /tmp/mysql-connector-java-5.1.45-bin.jar
    - hide_output: True

{% endif %}
