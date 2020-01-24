# JAVA/JDK - COMMON STATE
# OPTIONAL PILLAR PARAMETERS
#  version
#  user
{% from "common/map.jinja" import common with context %}

{% set product = 'java' %}
{% set version = salt['pillar.get']('version', common.oracle.java['product-version']) %}
{% set user = salt['pillar.get']('user', 'root') %}
{% set user_home = '/home/' + user %}
{% if user == 'root' %}
  {% set user_home = '/' + user %}
{% endif %}

{% if (version in salt['pillar.get']('global:oracle:' + product + ':supported-versions')) and (not common.oracle.java.srcpath == None) %}

  {% set package = salt['pillar.get']('global:oracle:' + product + ':supported-versions:' + version + ':package', None) %}
  {% if version|string == '1.7.0' %}

fetch from distro {{package}}:
  cmd.run:
    - name: |
        yum -y install {{package}}

  {% else %}

    {% set version_dir = '/opt/java/jdk' + version %}
    {% set uri = 'https://' + common.artifactory.user + ':' + common.artifactory.token + '@' + common.artifactory.host + common.oracle.java.srcpath + package %}

fetch {{package}}:
  cmd.run:
    - name: |
        mkdir -p /opt/java
        curl {{ uri }} -o /opt/java/{{ package }}
        cd /opt/java
        tar zxf {{package}} 
        ln -s {{ version_dir }}/ /opt/java/latest
      {% if not user == 'root' %}
        echo export JAVA_HOME=/opt/java/latest >> {{user_home}}/.bash_profile
        echo export JAVA='"$JAVA_HOME/bin/java"' >> {{user_home}}/.bash_profile
        echo export PATH='"$JAVA_HOME/bin:$PATH"' >> {{user_home}}/.bash_profile
        echo export JAVA_HOME=/opt/java/latest >> {{user_home}}/.bashrc
        echo export JAVA='"$JAVA_HOME/bin/java"' >> {{user_home}}/.bashrc
        echo export PATH='"$JAVA_HOME/bin:$PATH"' >> {{user_home}}/.bashrc
      {% endif %}
        echo export JAVA_HOME=/opt/java/latest >> /root/.bash_profile
        echo export JAVA='"$JAVA_HOME/bin/java"' >> /root/.bash_profile
        echo export PATH='"$JAVA_HOME/bin:$PATH"' >> /root/.bash_profile
        echo export JAVA_HOME=/opt/java/latest >> /root/.bashrc
        echo export JAVA='"$JAVA_HOME/bin/java"' >> /root/.bashrc
        echo export PATH='"$JAVA_HOME/bin:$PATH"' >> /root/.bashrc
        echo export PATH

  {% endif %}


{% else %}
invalid version {{version}} common {{product}} abort:
  cmd.run:
    - name: |
        echo Invalid version {{version}}
  module.run:
    - name: test.false
{% endif %}

