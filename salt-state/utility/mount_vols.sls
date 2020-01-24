# ########################################################################
# DEVICE CONFIGURATION
# GENERIC STATE TO MOUNT VOLUMES CREATED WHEN DEFINED IN CLUSTER 
# PROVISIONING FOR ANY PRODUCT GROUP 
# ** THIS STATE WILL NOT CONFIGURE RAIDS
# PILLAR - role is required OR grains role
#
# NOTE: AWS RENAMES DEVICES, THEREFORE WE MUST USED RENAMED NAME HERE
# 
# TIP: IF YOU ARE PROVISIONING INSTANCE WIL VOLUMES THAT YOU DO NOT WANT
# MOUNTED BY WAY OF THIS STATE, SET THEM IN THE PROVISIONING CONFIGURATION
# WITH pillar config raid: True
# 
# EXAMPLE
# /xvdf for /sdbf 
# /xvdh for /sdbh
#
# SUPPORTS PRODUCT GROUP ROLE EXTENSION
#
# TBD
# COULD MAKE THE HIGH LEVEL ACTIONS OPTIONAL SUCH A CREATE LABEL AND VALUES, 
# CREATE PARTITION AND VALUES, CREATE FILESYSTEM ND VALUES
# ##########################################################################

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

label {{ vol }} for {{ role}}:
  module.run:
    - name: partition.mklabel
    - device: {{ mod_device }}
    - label_type: msdos
    - unless: test -f {{ mod_device }}

create {{ vol }} partition for {{ role }}:
  module.run:
    - name: partition.mkpart
    - device: {{ mod_device }}
    - part_type: primary
    - start: '0' 
    - end: {{ size }}
    - unless: test -f {{ mod_device }}

create {{ vol }} filesystem for {{ role}}:
  module.run:
    - name: extfs.mkfs
    - device: {{ mod_device }}
    - fs_type: {{ fs_type }}

mount {{ vol }} filesystem for {{ role }}:
  mount.mounted:
    - name: /{{ vol }}
    - device: {{ mod_device }}
    - fstype: {{ fs_type }}
    - pass_num: {{ pass_num }}
    - dump: {{ dump }}
    - mkmnt: True
    - persist: True
        {% if opts|length > 0 %}
    - opts: {{opts|join(',')}}
        {% endif %}
    - unless: mount | grep \/{{ vol }}\ type

      {% endif %}
    {% endif %}
  {% endfor %}

process fstab for non raid volumes on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: utility.update_fstab
    - kwargs: {
          pillar: {
            volinfo-path: "{{ volinfo_path }}"
          }
      }
{% endif %}
