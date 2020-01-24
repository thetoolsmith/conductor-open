# UPDATE cassandra.yaml STATE
# THIS FILE HAS DEPENDENCY ON FILE PATHS DEFINED IN cassandra:directories in defaults.yaml

{% set role = grains['role'] %}
{% set product = role.split('.')[1] %}
{% set file_path = salt['pillar.get']('file-path', None) %}

{% if not file_path == None %}
 
set {{grains['role']}} cluster_name:
  file.replace:
    - name: {{file_path}}
    - pattern: cluster_name:.*$
    - repl: "cluster_name: '{{role}}_{{grains['salty.cassandra.cluster.id']}}'"
    - backup: .bak

set {{grains['role']}} num_tokens:
  file.replace:
    - name: {{file_path}}
    - pattern: ^# num_tokens:.*$
    - repl: 'num_tokens: 8'
    - backup: .bak

set {{grains['role']}} allocate_tokens_for_local_replication_factor:
  file.replace:
    - name: {{file_path}}
    - pattern: ^# allocate_tokens_for_local_replication_factor:.*$
    - repl: "allocate_tokens_for_local_replication_factor: 3"
    - backup: .bak

set {{grains['role']}} hints_directory:
  file.replace:
    - name: {{file_path}}
    - pattern: hints_directory:.*$
    - repl: 'hints_directory: /datalake/cassandra/hints'
    - backup: .bak

set {{grains['role']}} data_file_directories:
  file.replace:
    - name: {{file_path}}
    - pattern: "- /var/lib/cassandra/data.*$"
    - repl: "- /mnt/datalake_data/cassandra/data"
    - backup: .bak

set {{grains['role']}} commitlog_directory:
  file.replace:
    - name: {{file_path}}
    - pattern: commitlog_directory:.*$
    - repl: 'commitlog_directory: /datalake_commitlog/cassandra/commitlog'
    - backup: .bak

set {{grains['role']}} cdc_raw_directory:
  file.replace:
    - name: {{file_path}}
    - pattern: cdc_raw_directory:.*$
    - repl: 'cdc_raw_directory: /datalake/cassandra/cdc_raw'
    - backup: .bak

set {{grains['role']}} saved_caches_directory:
  file.replace:
    - name: {{file_path}}
    - pattern: saved_caches_directory:.*$
    - repl: 'saved_caches_directory: /datalake/cassandra/saved_caches'
    - backup: .bak

  {% set _seeds = grains['cluster.seed_nodes']|join(',') %}
  {% set replstring = '"' + _seeds + '"' %}
set {{grains['role']}} seeds:
  file.replace:
    - name: {{file_path}}
    - pattern: '- seeds: "127.0.0.1".*$'
    - repl: '- seeds: {{replstring}}'
    - backup: .bak

set {{grains['role']}} listen_address:
  file.replace:
    - name: {{file_path}}
    - pattern: listen_address:.*$
    - repl: "listen_address: {{grains['ipv4'][0]}}"
    - backup: .bak

set {{grains['role']}} native_transport_address:
  file.replace:
    - name: {{file_path}}
    - pattern: native_transport_address:.*$
    - repl: "native_transport_address: {{grains['ipv4'][0]}}"
    - backup: .bak

set {{grains['role']}} endpoint_snitch:
  file.replace:
    - name: {{file_path}}
    - pattern: endpoint_snitch:.*$
    - repl: 'endpoint_snitch: GossipingPropertyFileSnitch'
    - backup: .bak

# server_encryption_options (block)
set {{grains['role']}} encryption_options internode_encryption:
  file.replace:
    - name: {{file_path}}
    - pattern: internode_encryption:.*$
    - repl: 'internode_encryption: all'
    - backup: .bak

set {{grains['role']}} encryption_options keystore:
  file.replace:
    - name: {{file_path}}
    - pattern: keystore:.*$
    - repl: 'keystore: /datalake/.polaris/aabddejj/cassandra.keystore.jks'
    - backup: .bak

set {{grains['role']}} encryption_options keystore_password:
  file.replace:
    - name: {{file_path}}
    - pattern: keystore_password:.*$
    - repl: "keystore_password: {{ pillar['salty.role'][product]['encryption_options']['keystore_password'] }}" 
    - backup: .bak

set {{grains['role']}} server_encryption_options truststore:
  file.replace:
    - name: {{file_path}}
    - pattern: truststore:.*$
    - repl: 'truststore: /datalake/.polaris/aabddejj/cassandra.truststore.jks' 
    - backup: .bak

set {{grains['role']}} client_encryption_options truststore:
  file.replace:
    - name: {{file_path}}
    - pattern: '# truststore:.*$'
    - repl: 'truststore: /datalake/.polaris/aabddejj/cassandra.truststore.jks'
    - backup: .bak

set {{grains['role']}} server_encryption_options truststore_password:
  file.replace:
    - name: {{file_path}}
    - pattern: truststore_password:.*$
    - repl: "truststore_password: {{ pillar['salty.role'][product]['encryption_options']['truststore_password'] }}"
    - backup: .bak

set {{grains['role']}} client_encryption_options truststore_password:
  file.replace:
    - name: {{file_path}}
    - pattern: '# truststore_password:.*$'
    - repl: "truststore_password: {{ pillar['salty.role'][product]['encryption_options']['truststore_password'] }}"
    - backup: .bak

set {{grains['role']}} encryption_options protocol:
  file.replace:
    - name: {{file_path}}
    - pattern: '# protocol:.*$'
    - repl: 'protocol: TLS'
    - backup: .bak

set {{grains['role']}} encryption_options algorithm:
  file.replace:
    - name: {{file_path}}
    - pattern: '# algorithm:.*$'
    - repl: 'algorithm: SunX509'
    - backup: .bak

set {{grains['role']}} server_client_encryption_options store_type:
  file.replace:
    - name: {{file_path}}
    - pattern: '# store_type: JKS.*$'
    - repl: 'store_type: JKS'
    - backup: .bak

set {{grains['role']}} server_client_encryption_options cipher_suites:
  file.replace:
    - name: {{file_path}}
    - pattern: '# cipher_suites:.*$'
    - repl: 'cipher_suites: [TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA]'
    - backup: .bak

set {{grains['role']}} server_client_encryption_options require_client_auth:
  file.replace:
    - name: {{file_path}}
    - pattern: '# require_client_auth:.*$'
    - repl: 'require_client_auth: true'
    - backup: .bak

set {{grains['role']}} client_encryption_options enabled:
  file.replace:
    - name: {{file_path}}
    - pattern: ^client_encryption_options:\n.*.enabled:.*$
    - repl: 'client_encryption_options:\n    enabled: true'
    - backup: .bak

# transparent_data_encryption_options, reset changed keystore
set {{grains['role']}} transparent_data_encryption_options keystore:
  file.replace:
    - name: {{file_path}}
    - pattern: '^.*.parameters:\n.*.- keystore:.*$'
    - repl: '        parameters:\n          - keystore: conf/.keystore'
    - backup: .bak

set {{grains['role']}} transparent_data_encryption_options key_password:
  file.replace:
    - name: {{file_path}}
    - pattern: '^.*.store_type: JCEKS\n.*.key_password:.*$'
    - repl: "            store_type: JCEKS\n            key_password: {{ pillar['salty.role'][product]['encryption_options']['keystore_password'] }}"
    - backup: .bak

{% endif %}



