# ############################################################################
# GENERIC NEW INSTANCE STATE
# EXAMPLE OF A STATE THAT CAN SAFELY BE APPLIED TO ALL NEW PROVISIONED VM'S. 
# THE IDEA OF THIS IS TO HAVE A STARTUP STATE THAT IS 'SAFE' TO APPLY TO ANY 
# NEWLY PROVISIONED TARGET MINION.
# THIS STATE REALIZES ALL THE STATES THAT SHOULD BE APPLIED TO WHATEVER TARGET
# IT'S EXECUTED ON BASED ON THE ROLE/S THE MINION HAS.
# THEN APPLIES THE STATE. 
# 
# FOR THIS STATE TO HAVE ANY AFFECT WHEN APPLIED TO A MINION, IT REQUIRES THAT 
# MINION HAVE A ROLE STATE CONFIGURED IN IT'S STATE TREE IN THE PRODUCT GROUP HIERARCHY.
# FOR EXAMPLE:
# salt://salty/activemq/init.sls
#
# You can also set startup-override: yaml in the
# PROVISIONING TEMPLATE IN THE PILLAR TREE. I.E.
# salt-pillar repo /provisioning/templates/test_salty_roles.sls 
# activemq:
#   startup-override: ['state1','state2']
#   ....
#   ....
# refer to the template readme salt-pillar repo 
# /provisioning/templates/template.README
#
# ** FOR THIS STATE TO WORK, THERE IS A PILLAR STRUCTURE NEEDED
# config.common:roles
# This pillar must list all roles for all product groups that will
# be using this generic startup state.
# 
# ############################################################################

{% set state_pillars = salt['pillar.get']('statepillars', {}) %}

{% if 'pillar.environment' in grains %}

  {% set pillarenv = salt['grains.get']('pillar.environment', None) %}

  {% if pillarenv == None %}
exception_pillar.environment_required_grain:
  module.run:
    - name: test.exception
    - message: pillar.environment is required salt grain
  {% else %}

new instance start message:
  cmd.run:
    - name: |
        echo determining states for node {{ grains['id'] }}

    # filter is based on assuption env is part of the hostname
    {% set envfilter = '.' + pillarenv + '.' %}
    {% if envfilter in grains['id'] %}
      {% set roles = [] %}
      {% set getroles = salt['pillar.get']('config.common:roles') %}
      {% for therole in getroles %}
        {% do roles.append(therole) %}
      {% endfor %}
      {% set getroles = salt['pillar.get']('config.common:roles-composite') %}
      {% for thecompositerole in getroles %}
        {% do roles.append(thecompositerole) %}
      {% endfor %}
      {% set allstates = [] %}
      {% set iscomposite = salt['grains.get']('composite.role', None) %}
      # NOW ITERATE OVER ALL THE ROLE AND SEE WHAT THE NODE NEEDS
      {% for role in roles %}
        {% if ( (grains['role']|lower == role) or ((grains['product.group']|lower + '.' + role) ==  grains['role']|lower) or ((not iscomposite == None) and (role in grains['composite.role'])) ) %}
          {% if not iscomposite == None %}
            {% set baseroles = grains['composite.role'] %}
            {% for foo in baseroles %}
              {% set basestate = grains['product.group'] + '.role:' + foo + ':state' %}
              {% set base_states = salt['pillar.get'](basestate) %}
              {% for thestate in base_states %}
                {% if not thestate in allstates %}
                  {% do allstates.append(thestate) %}
                {% endif %}
              {% endfor %}
            {% endfor %}
          {% else %}
            {# could add this check if desired.... {% if grains['product.group'] in role %} #}
            {% set basestate = grains['product.group'] + '.role:' + role + ':state' %} 
            {% set base_states = salt['pillar.get'](basestate) %}
            {% for thestate in base_states %}
              {% if not thestate in allstates %}
                {% do allstates.append(thestate) %}
              {% endif %}
            {% endfor %}
          {% endif %}
        {% endif %}
      {% endfor %}
      {% set state_ctr = 0 %}
      {% for state in allstates %}
        {% set state_ctr = state_ctr|int + 1 %}
applying state {{ state_ctr }} {{ state }}:
  module.run:
    - name: state.sls
    - mods: {{ state }}
        {% for _s, _p in state_pillars.iteritems() %}
          {% if _s == state %}
    - kwargs: {
          pillar: {
            {% set pillarctr = 1 %}
            {% for _pk, _pv in _p.iteritems() %}
              {% if not pillarctr == _p|length %}
             {{_pk}}: {{_pv}},
              {% else %}
             {{_pk}}: {{_pv}}
              {% endif %}
              {% set pillarctr = pillarctr|int + 1 %}
            {% endfor %}
          }
      }
          {% endif %}
        {% endfor %}
      {% endfor %}

include:
  - common.base

    {% endif %}
  {% endif %}
{% endif %}

