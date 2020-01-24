# ######################################################################
# ORACLE CLIENT INSTALL STATE
# INSTALLS ORACLE CLIENT AND SQLPLUS CLIENT AND ALL PRERQUISITE PACKAGES
# ######################################################################

{% from "common/map.jinja" import common with context %}

{% set product = 'oracle-client' %}
{% set version = salt['pillar.get']('version', common.oracle.client.['product-version']) %}
{% if version == None %}
exception_no_version_{{product}}:
  module.run:
    - name: test.exception
    - message: version not found in defaults or pillar for {{product}}
{% endif %}

{% if common.oracle.client.srcpath == None %}
exception_null_srcpath_{{product}}:
  module.run:
    - name: test.exception
    - message: default srcpath not found in defaults for {{product}}
{% endif %}

{% set supportedversions = salt['pillar.get']('global:oracle:client:supported-versions', {}) %}
{% for k,v in supportedversions.iteritems() %}
  {% if version == k %}
    # TODO: need to check the md5 hash value as well
    # TODO: could also make package into packages list and loop over that since two packages are needed
    {% set thepackage = v['package'] %}
    {% set sqlplus_package = v['sqlplus_package'] %}
    {% set version_dir = '/opt/' + product + '/' + version %}
    {% set uri = 'https://' + common.artifactory.user + ':' + common.artifactory.token + '@' + common.artifactory.host + common.oracle.client.srcpath + version + '/' + thepackage %}
    {% set sqlplus_uri = 'https://' + common.artifactory.user + ':' + common.artifactory.token + '@' + common.artifactory.host + common.oracle.client.srcpath + version + '/' + sqlplus_package %}

# PREREQUISITE
libaio:
  pkg.installed

# PULL FROM ARTIFACTORY
fetch {{product}}:
  cmd.run:
    - name: |
        mkdir -p /opt/{{product}}/{{ version }}
        curl {{ uri }} -o /opt/{{product}}/{{ version }}/{{ thepackage }}
        cd /opt/{{product}}/{{ version }}
        rpm -ivh {{ thepackage }}
        curl {{ sqlplus_uri }} -o /opt/{{product}}/{{ version }}/{{ sqlplus_package }}
        rpm -ivh {{ sqlplus_package }}
    - unless:
      - test -f /opt/{{product}}/{{ version }}/{{thepackage}}
      - test -f /opt/{{product}}/{{ version }}/{{sqlplus_package}}

# CREATE ENVIRONMENT FOR DEFAULT USER
{% set major_minor = version[:4] %}

create {{product}} environment loader:
  file.touch:
    - name: /home/centos/sqlplus.sh
    - unless: test -f /home/centos/sqlplus.sh
  cmd.run:
    - names:
      - chmod +x /home/centos/sqlplus.sh

populate {{product}} environment loader:
  file.append:
    - name: /home/centos/sqlplus.sh
    - text: |
        export ORACLE_HOME=/usr/lib/oracle/{{major_minor}}/client64/
        export LD_LIBRARY_PATH=/usr/lib/oracle/{{major_minor}}/client64/lib/
        export PATH="$ORACLE_HOME/bin:$PATH"

  {% endif %}
{% endfor %}

