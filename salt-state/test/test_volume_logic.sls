# a test to run on a cluster instance

{% set role = salt['pillar.get']('role', None) %}

{% if role == None %}
exception_null_no_role_to_mount_vols:
  module.run:
    - name: test.exception
    - message: role pillar item not found
{% endif %}

{% set internal_role = salt['grains.get']('internal.role', None) %}
{% if (grains['role']|lower == role) %}
  {% set upstream_config = False %}
  {% set volinfo_path = role + ':volume-info' %}
  {% if 'cluster-config' in salt['pillar.get'](role) %}
    {% if (internal_role in salt['pillar.get'](role + ':cluster-config')) and ('upstream-config' in salt['pillar.get'](role + ':cluster-config:' + internal_role)) %}
      {% set upstream_config = salt['pillar.get'](role + ':cluster-config:' + internal_role + ':upstream-config') %}
    {% endif %}    
  {% else %}
    {% set upstream_config = True %}
  {% endif %}
  {% if not upstream_config == True %}
    {% set volinfo_path = role + ':cluster-config:' + internal_role + ':volume-info' %}
  {% endif %}
  {% set volumes = salt['pillar.get'](volinfo_path, None) %}

  {% for vol in volumes %}
    # EXCLUDE VOLUMES FOR RAID PURPOSES
    {% if ('tags' in  salt['pillar.get'](volinfo_path + ':' + vol)) and ('raid' in  salt['pillar.get'](volinfo_path + ':' + vol + ':tags')) and (salt['pillar.get'](volinfo_path + ':' + vol + ':tags:raid') == True)%}
test skipping {{vol}} tagged for raid use on {{grains['id']}}:
  cmd.run:
    - name: |
        echo skipping.... {{vol}}
    {% else %}
test mounting {{vol}} NOT tagged for raid use on {{grains['id']}}:
  cmd.run:
    - name: |
        echo mounting.... {{vol}}
    {% endif %}     
  {% endfor %}
{% endif %}
