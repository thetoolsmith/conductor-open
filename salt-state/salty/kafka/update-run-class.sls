# UPDATE kafka-run-class STATE
{% from "salty/map.jinja" import pgroup with context %}

{% set file_path = salt['pillar.get']('file-path',  pgroup.kafka['dest-path'] + '/kafka/bin/kafka-run-class') %}

# TODO: COULD MAKE THESE A LIST IN PILLAR IF THE OPTIONS CHANGE FREQUENTLY
{% if not file_path == None %}
{{file_path}} set KAFKA_JMX_OPTS:
  file.replace:
    - name: {{file_path}}
    - pattern: 'KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote.*$'
    - repl: 'KAFKA_JMX_OPTS="-Djava.net.preferIPv4Stack=true -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false "'
    - backup: .bak
{% endif %}

