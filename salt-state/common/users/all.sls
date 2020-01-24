# ####################################################

{% from "common/users/map.jinja" import all with context %}

{% for user in all.iteritems() %}

common.users create {{ user }}:
  user.present:
    - name: {{ user }}
    - fullname: {{ user.fullname }}
    - shell: /bin/bash
    - uid: {{ user.uid }}
    - groups:
      - sudo

common.users creare user tmp for {{ user }}:
  file.directory:
    - name: /home/{{ user }}/tmp
    - user: {{ user }}
    - group: {{ user }}
    - mode: 755 
    - makedirs: True

common.users create {{ user }} key:
  ssh_auth.present:
    - user: {{ user }}
    - name: {{ user.sshkey }}  

common.users add {{ user }} to sudo:
  file.managed:
    - name: /etc/sudoers.d/{{ user }}-sudo
    - mode: 440 

common.users modify sudo for {{ user }}:
  file.append:
    - name: /etc/sudoers.d/{{ user }}-sudo
    - text:
      - '{{ user }} ALL=(ALL) NOPASSWD:ALL'

{% endfor %}
