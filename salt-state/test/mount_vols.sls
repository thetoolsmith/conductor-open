{% set role = salt['pillar.get']('role', salt['grains.get']('role', None)) %}
{% set pass_num = salt['pillar.get']('pass-num', '0') %}
{% set dump = salt['pillar.get']('dump', '0') %}
{% set fs_type = salt['pillar.get']('fs-type', 'ext4') %}
{% set opts = salt['pillar.get']('mnt-opts', []) %}

{% if role == None %}
exception_null_no_role_to_mount_vols:
  module.run:
    - name: test.exception
    - message: role pillar or grains item not found
{% endif %}


{% set internal_role = salt['grains.get']('internal.role', None) %}
{% if (grains['role']|lower == role) %}

debug message foo:
  cmd.run:
    - name: |
        echo debug message............

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
    {% if 'raid' in  salt['pillar.get'](volinfo_path + ':' + vol) %}

skipping {{vol}} marked for raid use on {{grains['id']}}:
  cmd.run:
    - name: |
        echo skipping {{vol}} marked for raid use on {{grains['id']}}
    {% else %}
mounting {{vol}} NOT marked for raid use on {{grains['id']}}:
  cmd.run:
    - name: |
        echo mounting {{vol}} NOT marked for raid use on {{grains['id']}}

      # check pillar config for fs_type,dump, pass_num           
      {% if 'fs-type' in salt['pillar.get'](volinfo_path + ':' + vol) %}
         {% set fs_type = salt['pillar.get'](volinfo_path + ':' + vol + ':fs-type') %}
      {% endif %}

      {% if 'pass-num' in salt['pillar.get'](volinfo_path + ':' + vol) %}
         {% set pass_num = salt['pillar.get'](volinfo_path + ':' + vol + ':pass-num') %}
      {% endif %}

      {% if 'dump' in salt['pillar.get'](volinfo_path + ':' + vol) %}
         {% set dump = salt['pillar.get'](volinfo_path + ':' + vol + ':dump') %}
      {% endif %}

      {% if 'mnt-opts' in salt['pillar.get'](volinfo_path + ':' + vol) %}
         {% set opts = salt['pillar.get'](volinfo_path + ':' + vol + ':mnt-opts') %}
      {% endif %}

      {% set _stringsize = salt['pillar.get'](volinfo_path + ':' + vol + ':size', None) %}

      {% set device = salt['pillar.get'](volinfo_path + ':' + vol + ':device', None) %}
      {% if ((not device == None) and (not _stringsize == None )) %}
        {% set mod_device = device|replace("/sd", "/xvd") %}
        {% set size = "'" + _stringsize|string + "GB'" %}
      {% endif %}

    {% endif %}
  {% endfor %}

{% endif %}
