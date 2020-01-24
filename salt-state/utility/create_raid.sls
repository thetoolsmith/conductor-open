# ########################################################################
# RAID DEVICE CONFIGURATION
#
# GENERIC STATE TO CREATE RAID FROM PILLAR DATA
# PROVISIONING FOR ANY PRODUCT GROUP 
#
# /etc/fstab WILL BE UPDATED IN THIS STATE FOR RAIDS
#
# PILLAR - role is required OR grains role
#
# TO MARK A VOLUME FOR USE IN A RAID, SET THE raid: YOUR_RAID_NAME 
# PILLAR IN provisioning/templates TREE
# WHATEVER YOU DEFINED FOR YOUR_RAID_NAME, THAT MUST BE CONFIGURED IN 
# salt://PRODUCT_GROUP/ under the product (role) configuration 
# 
# SUPPORTS PRODUCT GROUP ROLE EXTENSION
# 
# THIS STATE REQUIRES DATA FROM 
# pillar://provisioning/templates/PRODUCT_GROUP_ROLE_CONFIG
# AND
# pillar://config/PRODUCT_GROUP/ROLE_CONFIG
# ##########################################################################

{% set role = salt['pillar.get']('role', salt['grains.get']('role', None)) %}
{% if role == None %}
exception_null_no_role_to_mount_vols:
  module.run:
    - name: test.exception
    - message: role pillar or grains item not found
{% endif %}
{% set product = role.split('.')[1] %}
{% set product_group = role.split('.')[0] %}
{% set pass_num = salt['pillar.get']('pass-num', '0') %}
{% set dump = salt['pillar.get']('dump', '0') %}
{% set fs_type = salt['pillar.get']('fs-type', 'ext4') %}
{% set opts = salt['pillar.get']('mnt-opts', []) %}
{% set raid_level = salt['pillar.get']('raid-level', '0') %}
{% set raid_size = salt['pillar.get']('raid-size', None) %}
{% set raid_label = salt['pillar.get']('raid-label', None) %}
{% set mount_dir = salt['pillar.get']('mount-dir', '/') %}
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

  
  # ITERATE OVER ALL RAIDS DEFINED IN PRODUCT ROLE CONFIG IF RAID IS DEFINED, INTERATE VOLUME PROVISIONING INFO LOOKING FOR 
  # VOLUMES MARKED FOR THE RAID, THEN CREATE THE RAID
  {% set volumes = salt['pillar.get'](volinfo_path, None) %}

  {% if 'raid' in salt['pillar.get'](product_group + '.role:' + product) %}
    {% set raids_pillar = product_group + '.role:' + product + ':raid' %}
    {% set raids = salt['pillar.get'](raids_pillar, None) %}
    {% for raid_name in raids %}
      {% set raid_pillar_path = product_group + '.role:' + product + ':raid:' + raid_name %}
      {% if 'device' in salt['pillar.get'](raid_pillar_path) %}
         {% set raid_device = salt['pillar.get'](raid_pillar_path + ':device') %}
      {% endif %} # /RAID_NAME GETS APPENDS TO MOUNT-DIR
      {% if 'mount-dir' in salt['pillar.get'](raid_pillar_path) %}
         {% set mount_dir = salt['pillar.get'](raid_pillar_path + ':mount-dir') %}
      {% else %}
        {% set mount_dir = '/' %}
      {% endif %}
      {% if 'fs-type' in salt['pillar.get'](raid_pillar_path) %}
         {% set fs_type = salt['pillar.get'](raid_pillar_path + ':fs-type') %}
      {% endif %}
      {% if 'pass-num' in salt['pillar.get'](raid_pillar_path) %}
         {% set pass_num = salt['pillar.get'](raid_pillar_path + ':pass-num') %}
      {% endif %}
      {% if 'dump' in salt['pillar.get'](raid_pillar_path) %}
         {% set dump = salt['pillar.get'](raid_pillar_path + ':dump') %}
      {% endif %}
      {% if 'level' in salt['pillar.get'](raid_pillar_path) %}
         {% set raid_level = salt['pillar.get'](raid_pillar_path + ':level') %}
      {% endif %}
      {% if 'size' in salt['pillar.get'](raid_pillar_path) %}
         {% set raid_size = salt['pillar.get'](raid_pillar_path + ':size') %}
      {% endif %}
      {% if 'mnt-opts' in salt['pillar.get'](raid_pillar_path) %}
         {% set opts = salt['pillar.get'](raid_pillar_path + ':mnt-opts') %}
      {% endif %}
      {% if 'description' in salt['pillar.get'](raid_pillar_path) and 'LABEL' in salt['pillar.get'](raid_pillar_path + ':description')%}
         {% set raid_label = salt['pillar.get'](raid_pillar_path + ':description') %}
      {% endif %}

      {% set raid_volumes = [] %}
      # COLLECT ALL VOLUMES MARKED FOR THIS RAID
      {% for vol in volumes %}
        {% if ('raid' in  salt['pillar.get'](volinfo_path + ':' + vol)) and (salt['pillar.get'](volinfo_path + ':' + vol + ':raid') == raid_name)%}
          {% set vol_device = salt['pillar.get'](volinfo_path + ':' + vol + ':device', None) %}
          {% if not vol_device == None %}
            {% set mod_vol_device = vol_device|replace("/sd", "/xvd") %}
            {% do raid_volumes.append(mod_vol_device) %}
          {% endif %}
        {% endif %}
      {% endfor %}

      # CREATE RAID
CREATE {{raid_name}} {{raid_device}} on {{grains['id']}} for {{role}}:
      {% set num_devices = raid_volumes|length %}
  cmd.run:
    - name: |
        mdadm --create --verbose {{raid_device}} --level={{raid_level}} --name={{raid_name}} --raid-devices={{num_devices|string}} {{raid_volumes|join(' ')}}
    - unless: 
      {% for vol in raid_volumes %}
        - blkid {{vol}}
      {% endfor %}


      # WAIT FOR RAID (can use any of the volumes using to create the array)
wait for device {{raid_volumes[0]}} for raid {{raid_name}} on {{grains['id']}} for {{role}}:
  loop.until:
    - name: disk.blkid
    - condition: ("{{raid_volumes[0]}}" in m_ret)
    - period: 5
    - timeout: 20
    - m_args:
      - {{raid_volumes[0]}}
    - m_kwargs: {}

      # CREATE FILESYSTEM
CREATE filesystem and mount {{raid_name }} {{raid_device}} on {{grains['id']}} for {{ role}}:
  cmd.run:
    - name: |
      {% if not raid_label == None %}
        mkfs -t {{fs_type}} -L {{raid_label}} {{raid_device}}
      {% else %}
        mkfs -t {{ fs_type }} {{ raid_device }}
      {% endif %}
        mkdir -p {{mount_dir}}/{{raid_name}}
    - unless: blkid {{raid_device}}

      # WAIT FOR FILESYSTEM
wait for filesystem {{raid_device}} for raid {{raid_name}} on {{grains['id']}} for {{role}}:
  loop.until:
    - name: disk.blkid
    - condition: ("{{raid_device}}" in m_ret)
    - period: 5
    - timeout: 20
    - m_args:
      - {{raid_device}}
    - m_kwargs: {}

      # UPDATE FSTAB
process fstab for {{raid_name}} on {{grains['id']}}:
      {% if not raid_label == None %}
        {% set fstab_entry = raid_label + ' ' + mount_dir + '/' + raid_name + ' ' + fs_type + ' ' + opts|join(',') + ' ' + dump|string + ' ' + pass_num|string %}
      {% else %}
        {% set fstab_entry = raid_device + ' ' + mount_dir + '/' + raid_name + ' ' + fs_type + ' ' + opts|join(',') + ' ' + dump|string + ' ' + pass_num|string %}
      {% endif %}
  file.replace:
    - name: /etc/fstab
    - pattern: "^{{raid_device}}.*$"
    - repl: {{fstab_entry}}
    - backup: .bak
    - append_if_not_found: True

      # MOUNT
MOUNT {{raid_name}} {{raid_device}} on {{grains['id']}} for {{role}}:
  cmd.run:
    - name: |
        mount {{raid_device}} {{mount_dir}}/{{raid_name}}
    - unless: mount | grep {{raid_device}}

    {% endfor %}
  {% endif %}
{% endif %}
