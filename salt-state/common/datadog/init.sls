# DATADOG - COMMON STATE
{% import_yaml "common/datadog/defaults.yaml" as defaults %}

{% if not defaults.datadog.agent['api-key'] == 'unspecified' %}
install datadog agent on {{grains['id']}} role {{grains['role']}}:
  cmd.run:
    - name: |
        DD_API_KEY={{defaults.datadog.agent['api-key']}} bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"

verify datadog-agent status {{grains['id']}} role {{grains['role']}}:
  module.run:
    - name: service.status
    - m_name: datadog-agent
{% endif %}
