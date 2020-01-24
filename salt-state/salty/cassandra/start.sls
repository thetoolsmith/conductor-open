# START DATASTAX AGENT
# grep "DSE startup complete" /datalake/cassandra/logs/system.log
{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}

start {{defaults.cassandra['service-name']}} for {{grains['role']}}:
  module.run:
    - name: service.start
    - m_name: {{defaults.cassandra['service-name']}}
# need to add a wait using saltstack loop module

status {{defaults.cassandra['service-name']}} for {{grains['role']}}:
  module.run:
    - name: service.status
    - m_name: {{defaults.cassandra['service-name']}}

