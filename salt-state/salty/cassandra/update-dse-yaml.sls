# UPDATE dse.yaml STATE
{% import_yaml "salty/cassandra/defaults.yaml" as defaults %}

{% set role = grains['role'] %}
{% set product = role.split('.')[1] %}
{% set file_path = salt['pillar.get']('file-path', None) %}

{% if not file_path == None %}
  {% if 'authentication_options' in defaults.cassandra %}
    {% set authen_options = defaults.cassandra['authentication_options'] %}
set {{grains['role']}} {{file_path}} authentication_options enable:
  file.replace:
    - name: {{file_path}}
    - pattern: '^(#|a).*uthentication_options:\n(#|\W).*enabled:.*\n(#|\W).*default_scheme:.*\n(#|\W).*other_schemes:.*\n(#|\W).*scheme_permissions:.*\n(#|\W).*allow_digest_with_kerberos:.*\n(#|\W).*plain_text_without_ssl:.*\n(#|\W).*transitional_mode:.*$'
    - repl: "authentication_options:\n    enabled: {{authen_options['enabled']}}\n    default_scheme: {{authen_options['default_scheme']}}\n#    other_schemes:\n#    scheme_permissions: false\n    allow_digest_with_kerberos: {{authen_options['allow_digest_with_kerberos']}}\n    plain_text_without_ssl: {{authen_options['plain_text_without_ssl']}}\n    transitional_mode: {{authen_options['transitional_mode']}}"
    - backup: .original
  {% endif %}

set {{grains['role']}} {{file_path}} role_management_options mode:
  file.replace:
    - name: {{file_path}}
    - pattern: '^(#|r).*ole_management_options:\n(#|\W).*mode: internal'
    - repl: "role_management_options:\n    mode: internal"
    - backup: .bak

  {% if 'authorization_options' in defaults.cassandra %}
    {% set auth_options = defaults.cassandra['authorization_options'] %}
set {{grains['role']}} {{file_path}} authorization_options mode:
  file.replace:
    - name: {{file_path}}
    - pattern: '^(#|a).*uthorization_options:\n(#|\W).*enabled:.*\n(#|\W).*transitional_mode:.*\n(#|\W).*allow_row_level_security:.*$'
    - repl: "authorization_options:\n    enabled: {{auth_options['enabled']}}\n    transitional_mode: {{auth_options['transitional_mode']}}\n    allow_row_level_security: {{auth_options['allow_row_level_security']}}"
    - backup: .bak
  {% endif %}
{% endif %}



