# ROLE STATE
{% from "common/map.jinja" import common with context %}
{% from "salty/map.jinja" import pgroup with context %}

{% set role = salt['pillar.get']('role', salt['grains.get']('role', 'salty.cassandra')) %}
{% set product = role.split('.')[1] %}
{% set version = salt['pillar.get']('version', salt['pillar.get']('salty.role:' + product + ':product-version', pgroup.cassandra['product-version'])) %}
{% set dest_path = None %}
{% if 'dest-path' in pgroup.cassandra %}
  {% set dest_path = pgroup.cassandra['dest-path'] %}
{% endif %}

{% set env_vars = {} %}

{% if version in salt['pillar.get']('global:apache:cassandra:supported-versions') %}

include:
  - common.base

# CREATE LOCAL APPUSER IF NOT DEFAULT CLOUD USER 
  {% if not salt['pillar.get']('ami-user-map:' + grains['os']) == pgroup.cassandra['appuser'] %}
{{role}}_user:
  user.present:
    - name: {{pgroup.cassandra['appuser']}}
    - gid: {{pgroup.cassandra['appgroup']}}
    - shell: /bin/bash
    - createhome: True
    - require:
      - group: {{role}}_group
{{role}}_group:
  group.present:
    - name: {{pgroup.cassandra['appgroup']}}
  {% endif %}

# MOUNT VOLUMES (mount_vols and crearte_raid states could be put in base and run for everything since it depends on pillar config)
mount volumes for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.mount_vols
    - kwargs: {
          pillar: {
            role: {{ role }}
          }
      }
# CREATE RAID
create raid for {{role}}:
  module.run:
    - name: state.sls
    - mods: utility.create_raid

# CALL COMMON ROLE STATE
call common state for {{ role }}: 
  module.run:
    - name: state.sls
    - mods: common.apache.cassandra
    - kwargs: {
          pillar: {
  {% if not version == None %}
            version: {{ version }}, 
  {% endif %}
  {% if not pgroup.cassandra['java-version'] == None %}
            java-version: {{ pgroup.cassandra['java-version'] }}, 
  {% endif %}
  {% if not dest_path == None %}
            dest-path: {{ dest_path }}, 
  {% endif %}
  {% if 'repo-state' in pgroup.cassandra %}
            repo-state: {{ pgroup.cassandra['repo-state'] }},
  {% endif %}
  {% if 'appuser' in pgroup.cassandra %}
            user: {{ pgroup.cassandra['appuser'] }}, 
  {% endif %}
  {% if 'appgroup' in pgroup.cassandra %}
            group: {{ pgroup.cassandra['appgroup'] }}, 
  {% endif %}
            product: cassandra
          }   
      }   
    - require:
      - sls: common.base

  # INSTALL ADDITIONAL PACKAGES
  {% if 'additional-packages' in pgroup.cassandra %}
    {% for p in pgroup.cassandra['additional-packages'] %}
fetch from distro {{p}} {{role}}:
  cmd.run:
    - name: |
        yum -y install {{p}}
    {%  endfor %}
  {% endif %}

  # ADD CUSTOM JAVA SYMLINK
  {% if not pgroup.cassandra['java-version'] == None %}
create java symlink {{role}}:
    {% set version_dir = '/opt/java/jdk' + pgroup.cassandra['java-version'] %}
    {% set java_minor = pgroup.cassandra['java-version'].split('.')[1] %}
  cmd.run:
    - name: |
        ln -s {{ version_dir }}/ /opt/java{{java_minor}}
    - unless:
      - ls /opt/java{{java_minor}}
  {% endif %}

  # SET OWNER ON DEST PATH (SHOULD BE MOUNTED VOLUME)
  {% if not dest_path == None %}  
set owner for {{ dest_path }} for {{role}}:
  file.directory:
    - name: {{ dest_path }}
    - user: {{pgroup.cassandra['appuser']}}
    - group: {{pgroup.cassandra['appgroup']}}
    - recurse:
      - user
      - group
  {% endif %}

  # CREATE ADDITIONAL DIRECTORIES WITH PER USER PERMS
  {% if 'directories' in pgroup.cassandra %}
    {% for user in pgroup.cassandra['directories'] %}
      {% for d in pgroup.cassandra['directories'][user] %}
create {{d}} for {{role}}:
  file.directory:
    - name: {{d}}
    - makedirs: True
    - user: {{user}}
    - group: {{user}}
    - mode: 755 
      {% endfor %}
    {% endfor %}
  {% endif %}

  # APPLY SET LOCAL ENVIRONMENT STATE
apply local environment state for {{role}}:    
  module.run:
    - name: state.sls
    - mods: salty.cassandra.set-environment
    - kwargs: {
          pillar: {
            env-vars: {{ env_vars }}
          }
      }

  # UPDATE cassandra.yaml
update cassandra.yaml file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.cassandra.update-cassandra-yaml
    - kwargs: {
          pillar: {
            file-path: {{pgroup.cassandra['home']}}/cassandra.yaml
          }
      }
    - onlyif: test -f {{pgroup.cassandra['home']}}/cassandra.yaml

  # UPDATE cassandra-rackdc.properties
update cassandra-rackdc.properties file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.cassandra.update-cassandra-rackdc-properties
    - kwargs: {
          pillar: {
            file-path: {{pgroup.cassandra['home']}}/cassandra-rackdc.properties
          }
      }
    - onlyif: test -f {{pgroup.cassandra['home']}}/cassandra-rackdc.properties

  # UPDATE cassandra-env.sh
update cassandra-env.sh file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.cassandra.update-cassandra-env-sh
    - kwargs: {
          pillar: {
            file-path: {{pgroup.cassandra['home']}}/cassandra-env.sh
          }
      }
    - onlyif: test -f {{pgroup.cassandra['home']}}/cassandra-env.sh

  # UPDATE dse-env.sh
update dse-env.sh file for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.cassandra.update-dse-env-sh
    - kwargs: {
          pillar: {
            file-path: {{pgroup.cassandra['home-parent']}}/dse-env.sh
          }
      }
    - onlyif: test -f {{pgroup.cassandra['home-parent']}}/dse-env.sh

  # UPDATE dse.yaml
update dse.yaml file for {{role}}:    
  module.run:
    - name: state.sls
    - mods: salty.cassandra.update-dse-yaml
    - kwargs: {
          pillar: {
            file-path: {{pgroup.cassandra['home-parent']}}/dse.yaml
          }   
      }   
    - onlyif: test -f {{pgroup.cassandra['home-parent']}}/dse.yaml

  # UPDATE datastax agent address.yaml
update address.yaml file for {{role}}:    
  module.run:
    - name: state.sls
    - mods: salty.cassandra.update-address-yaml
    - kwargs: {
          pillar: {
            file-path: /var/lib/datastax-agent/conf/address.yaml
          }   
      }   
    - onlyif: test -f /var/lib/datastax-agent/conf/address.yaml

  # NOTE: NO SERVICE INIT.D FILE CHANGES /etc/init.d/dse 

  # START CASSANDRA (dse) SERVICE
assure start {{pgroup.cassandra['service-name']}} for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.cassandra.start
    - onlyif: test -f /etc/init.d/{{pgroup.cassandra['service-name']}}

  # INIT AND START DATASTAX AGENT SERVICE
  # TODO: NOTE DATASTAX-AGENT dse WILL NOT START UNTIL THE KEYSTORE IS CREATED AND CERTS ARE GENERATED
  # THAT THE cassandra.yaml FILE HAS CONFIGURED BASED ON OUR CONFIG. REFER TO dse_service_README
init datastax-agent for {{role}}:
  module.run:
    - name: state.sls
    - mods: salty.cassandra.start-datastax-agent
    - onlyif: test -f /etc/init.d/datastax-agent

  # APPLY MONITORING STATES
monitoring for {{role}} on {{grains['id']}}:
  module.run:
    - name: state.sls
    - mods: salty.monitoring
    - kwargs: {
          pillar: {
    {% if 'appuser' in pgroup.cassandra %}
            user: {{pgroup.cassandra['appuser']}},
    {% endif %}
            service: cassandra
          }
      }

  # FETCH AND APPLY CQL SEED DATA
  {% if 'csql' in pgroup.cassandra and 'package' in pgroup.cassandra['csql']%}
fetch {{pgroup.cassandra['csql']['package']}} for {{role}}:
  cmd.run:
    - output_loglevel: quiet
    - name: |
        curl {{common.artifactory.connector}}{{pgroup.cassandra.csql['path']}}/{{pgroup.cassandra.csql['package']}} -o {{pgroup.cassandra.csql['package']}}
        chmod 777 {{pgroup.cassandra.csql['package']}}
        # cqlsh THIS_HOST -u cassandra -p cassandra  -f cassandra-setup-datalake.cql
        # this csql gets executed only on one instance of the cluster, use primary. may need to make an orch state for this if depends on all members running services up
  {% endif %}

{% else %}
# THIS WILL RETURN STATUS CODE 11
invalid version {{role}} message:
  module.run:
    - name: test.exception
    - message: invalid version {{version}}
{% endif %}
