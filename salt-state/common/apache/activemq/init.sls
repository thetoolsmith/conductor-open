# ##############################
# GENERIC activemq INSTALL STATE
# ##############################
{% from "common/apache/activemq/map.jinja" import activemq with context %}

{% set product = activemq['product-name'] %}
{% set role = salt['pillar.get']('role', product) %} #role passed in pillar such as role=devops.rabbitmq
{% set version = salt['pillar.get']('version', activemq['product-version']) %}

{% if version in salt['pillar.get']('global:apache:' + product + ':supported-versions', {}) %}
# we would use pkg.installed to make this more generic regardless of the OS platform
installing {{product}} for {{role}}:
  cmd.run:
    - name: |
        yum -y install wget
        yum -y install java-1.8.0-openjdk
        yum -y install java-1.8.0-openjdk-devel
        echo export JAVA_HOME=/usr/java/jdk1.8.0_131/ >> /root/.bash_profile
        echo export JRE_HOME=/usr/java/jdk1.8.0_131/jre >> /root/.bash_profile
        wget https://archive.apache.org/dist/{{product}}/{{version}}/apache-{{ product }}-{{ version }}-bin.tar.gz
        tar -zxvf apache-activemq-*-bin.tar.gz -C /var
        mv /var/apache-activemq-*/ /var/activemq/

{% else %}
invalid version {{version}} common {{product}} abort:
  cmd.run:
    - name: |
        echo Invalid version
  module.run:
    - name: test.false
{% endif %}
