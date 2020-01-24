# ############################################################################
# DEVICE DESCRIPTION CONFIGURATION
# GENERIC STATE TO UPDATE THE /etc/fstab file DEVICE DESCRIPTION (FIRST FIELD)
#
# VALID CONDITIONS
# PILLAR VOLUME CONFIG HAS description: UUID set
# or
# PILLAR VOLUME CONFIG HAS description LABEL set
#
# REQUIRED INPUT 
# role PILLAR OR grains role
# volinfo-path PILLAR
#   EXAMPLES:
#      salty.zookeeper:cluster-config:secondary:volume-info (not upstream)
#      salty.cassandra:volume-info                          (upstream)
# 
# RAID SETS ARE NOT SUPPORTED IN THIS STATE 
# (pillar volumes with config of raid: True)
#
# SETTING UUID OR LABEL FOR DEVICE COULD BE DONE IN mount_vols STATE BUT 
# THAT REQUIRES SALT.MODULE.DISK WHICH REQUIRED blkid UTILITY TO BE ON THE 
# SYSTEM. SO TO AVOID THE DEPENDENCY, WE HAVE THIS TASK IN A SEPARETE STATE 
# THAT CAN OPTIONALLY BE APPLIED PER PRODUCT GROUP AND ROLE
#
# mount_vols.sls WILL CREATE FSTAB ENTRIES USING THE DEVICE NAME BY DEFAULT 
# create_raid.sls does NOT need this state. fstab updates happen directly
# 
# SUPPORTS PRODUCT GROUP ROLE EXTENSION
# #############################################################################

{% set role = salt['pillar.get']('role', salt['grains.get']('role', None)) %}
{% set volinfo_path = salt['pillar.get']('volinfo-path', None) %}

{% if not volinfo_path == None %}
  {% set volumes = salt['pillar.get'](volinfo_path, None) %}
  {% for vol in volumes %}
    {% set device = salt['pillar.get'](volinfo_path + ':' + vol + ':device') %}
    # UUID
    {% if ('description' in  salt['pillar.get'](volinfo_path + ':' + vol)) and (salt['pillar.get'](volinfo_path + ':' + vol + ':description') == 'UUID')%}
utility set device description {{ vol }} for {{ role}}:
  cmd.run:
    - name: |
        UUID=`lsblk {{device}} -o UUID -l --noheadings --nodeps`
        NAME=`lsblk {{device}} -o NAME -l --noheadings --nodeps`
        sed -i "s|^\/dev\/${NAME}|UUID=${UUID}|g" /etc/fstab
    {% endif %}

    # LABEL
    {% if ('description' in  salt['pillar.get'](volinfo_path + ':' + vol)) and ('LABEL=' in salt['pillar.get'](volinfo_path + ':' + vol + ':description'))%}
      {% set label = salt['pillar.get'](volinfo_path + ':' + vol + ':description').split('=')[1] %}
utility set device description {{ vol }} for {{ role}}:
  cmd.run:
    - name: |
        NAME=`lsblk {{device}} -o NAME -l --noheadings --nodeps`
        sed -i "s|^\/dev\/${NAME}|LABEL={{label}}|g" /etc/fstab
    {% endif %}
  {% endfor %}

utility format fstab columns:
  cmd.run:
    - name: |
        #column -t /etc/fstab
        sed -i "s/\t/ /g" /etc/fstab

{% endif %}
