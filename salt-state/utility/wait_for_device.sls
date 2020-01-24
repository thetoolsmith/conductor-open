# ########################################################################################################
# DEVICE WAIT STATE
# THIS STATE WILL WAIT FOR A DEVICE TO BE AVAILABLE
# REQUIRES blkid TO EXIST ON THE SYSTEM AS PER SALT MODULE DOCUMENTATION
# REF:https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.disk.html#module-salt.modules.disk
# REF: https://docs.saltstack.com/en/latest/ref/states/all/salt.states.loop.html#module-salt.states.loop
#
# REQUIRED DYNAMIC PILLAR:
# device (full device path, example /dev/xvdf
#
# OPTIONAL PILLAR
# period - seconds to wait between intervals
# timeout - timeout
#
# NOTES ABOUT THE condition evaluation
# the condition for this is a bit different due to the disk.blkid module return
# it sets the 1st key in the ret dict to the device, therefore is the device doesn't exist yet, the 
# loop.until will fail instead of looping because of key error.
# so for the disk.blkid execution module we have to set condition to one or two values that work.
# condition: see below
# or
# condition: m_ret
# The latter simply evaluates whether the loop returns or not, BUT both work in this case.
# ########################################################################################################

# the device in case of raid /dev/md0 will not appear in the blkid command until its mounted
# so might need to wait for grep -i active /proc/mdstat | grep raid0 which will return exit code 0 if exists
# or look for ['LABEL'] IN m_ret[device] in m_ret and match 
# this command can work too: mdadm --detail /dev/md0
# wait on mkfs command might be needed, when done blkid returns this: /dev/md0: LABEL="datalake_data"
{% set device = salt['pillar.get']('device', None) %}
{% set period = salt['pillar.get']('period', '5') %}
{% set timeout = salt['pillar.get']('timeout', '20') %}

{% if not device == None %}
utility wait for device:
  loop.until:
    - name: disk.blkid
    - condition: ("{{device}}" in m_ret)
    - period: {{period|int}}
    - timeout: {{timeout|int}}
    - m_args:
      - {{device}}
    - m_kwargs: {}
{% endif %}
