# #########################################################################
# GENERIC 3RD PARTY SERVICE START STATE
#
# input:
# service - the daemon name
# bootstart - True|False (default is None which does nothing)
#
# If specifying only the service name, there must be a script
# in /etc/init.d OR the daemon must be in pillar
# pillar//global:managed-services:xxxxx
# This is a daemon to command map
#
# If the service does not have /etc/init.d and is not in pillar
# use the full path to start script.
# example:
# salt-call state.sls common.start pillar='{service: /path/to/bin/activemq}'
#
# instead of:
# salt-call state.sls common.start pillar='{service: activemq}'
#
# TIP:
# due to logic in salt state, if service is path and not in pillar managed
# then bootstart is ignored
# #########################################################################

{% set service = salt['pillar.get']('service', None) %}
{% set bootstart = salt['pillar.get']('bootstart', None) %}
{% if service == None %}
exception_MISSING_SERVICE_PARAMETER:
  module.run:
    - name: test.exception
    - message: service is a dynamic pillar parameter for this state
{% else %}
  {% if 'managed-services' in salt['pillar.get']('global') %}
    {% set managed_services = salt['pillar.get']('global:managed-services', {}) %}
  {% else %}
    {% set managed_services = {} %}
  {% endif %}
  {% for k,v in managed_services.iteritems() %}
    {% if k == service %}
start {{v}} service:
      {% if '/' in v %}
  cmd.run:
    - name: |
        {{v}} start
      {% else %}
  service.running:
    - name: {{v}}
    - sig: {{k}}
    - enable: {{bootstart}}
      {% endif %}
    {% endif %}
  {% endfor %}
  # IF NOT MANAGED IN PILLAR
  {% if not service in salt['pillar.get']('global:managed-services') %}
start {{service}} service:
    {% if '/' in service %}
  cmd.run:
    - name: |
        {{service}} start
    {% else %}
  service.running:
    - name: {{service}}
    - sig: {{service}}
    - enable: {{bootstart}}
    {% endif %}
  {% endif %}

{% endif %}

