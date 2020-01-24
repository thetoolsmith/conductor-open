# #################################################
# GENERIC INSTALLER STATE FOR ALL PRODUCT GROUP
# #################################################


***** needs refactoring
***** something like this can be used if there is consistency in how products, applications, services, libs are packaged and/or deployed
***** for example if we build and packaged all our services the same, we could use a generic service install salt state which is what this was previously





{% from "common/map.jinja" import XXX with context %}
{% from "map.jinja" import versions with context %}

# THESE THREE VARIABLES ARE SET IF THEY HAVE BEEN SET IN PILLAR BEFORE CALLING THIS STATE
{% set role = salt['pillar.get']('role', None) %}
{% set dependency = salt['pillar.get']('dependency', False) %}
{% set productversion = salt['pillar.get']('version', None) %}

{% if role == None %}
exception_XXXinstall_MISSING_ROLE_PARAMETER:
  module.run:
    - name: test.exception
    - message: role is a dynamic pillar parameter for this state
{% else %}
  {% set productgroup = salt['grains.get']('product.group') %}
  # try cross product group dependencies
  {% if dependency == True %}
    {% set productgroup = salt['pillar.get']('config.common:role-group-map:' + role, None) %}
  {% endif %}
  {% set iscomposite = salt['grains.get']('composite.role', None) %}
  {% set productversion = salt['pillar.get']('version', None) %}
  {% if ( (dependency == True) or ( (grains['role']|lower == role) or ((not iscomposite == None) and (role in grains['composite.role'])))) %}
    {% set role_config = productgroup + '.role:' + role %}
    {% set rolecfgobject = salt['pillar.get'](role_config, None) %}
    {% set rolehaspath = salt['pillar.get'](role_config, None)['product-path'] %}
    # use role specific product-path, otherwise use product group product-path value, or None (will exit)
    {% set productpath = salt['pillar.get'](role_config, salt['pillar.get'](productgroup + '.role', None)['product-path'])['product-path'] %}
    # use role specific source-path to artifactory repo or use default repo for this environment
    {% set sourcepath = salt['pillar.get'](role_config, XXX.artifactory.repo.path )['source-path'] %}
    {% set productname = salt['pillar.get'](role_config, None)['product-name'] %}
    {% if productversion == None %}
      {% set productversion = versions[role]['version'] %}
    {% endif %}
    {% set package = versions[role]['package'] %}
    {% set packagename = salt['pillar.get'](role_config, None)['package-name'] %}
    # THREE OPTIONS HERE: pillar role specific version, pillar common version, state default versions for tomcat and java
    {% set tomcat_version = salt['pillar.get'](role_config + ':tomcat:version', salt['pillar.get']('config.common:tomcat:version', XXX.tomcat.version)) %}
    {% set jdk_version = salt['pillar.get'](role_config + ':java:version', salt['pillar.get']('config.common:java:version', XXX.java.version)) %}

    {% set tomcat_instance = [] %}
    # TOMCAT INSTANCE
    {% if 'tomcat' in salt['pillar.get'](role_config) %}
      {% if 'instance' in salt['pillar.get'](role_config + ':tomcat') %}
        {% set testvar = salt['pillar.get'](productgroup + '.role:' + role + ':tomcat:instance') %}
        {% if (not testvar is iterable) and (testvar is not string) %}
          {% do tomcat_instance.append(testvar|int) %}
        {% elif (testvar is iterable) and (testvar is not string) %}
          {% for x in testvar %}
            {% do tomcat_instance.append(x) %}
          {% endfor %}  
        {% else %}
          {% set dummy = None %} 
        {% endif %}
      {% else %}
        # NOT SURE IF WE WILL NEED A DEFAULT
        {% set dummy = None%} 
      {% endif %}
    {% else %}
      # NOT SURE IF WE WILL NEED A DEFAULT
      {% set dummy = None %} 
    {% endif %}  

    {% if ((productname == None) or (productversion == None) or (package == None) or (productpath == None)) %}
exception_config_{{productname}}:
  module.run:
    - name: test.exception
    - message: one or more required keys has no value...productpath, productname, productversion, package, package-name
    {% endif %}

    {% if ((not XXX.artifactory.host == None) and (not sourcepath == None)) %}
      {% if rolehaspath == None %}
        {% set packagepath = 'https://' + XXX.artifactory.user + ':' + XXX.artifactory.token + '@' + XXX.artifactory.host + sourcepath + productpath + productname + '/' + productversion + '/' + package %}
      {% else %}
        {% set packagepath = 'https://' + XXX.artifactory.user + ':' + XXX.artifactory.token + '@' + XXX.artifactory.host + sourcepath + productpath + '/' + package %}
      {% endif %}


# INSTALL TOMCAT AND JAVA IN THIS STATE ONLY IF THEY DON'T EXIST.
# IF A FULL RE-INSTALL IS NEEDED, THEN APPLY THOSE STATES INSTEAD.
install jdk {{jdk_version}} for {{role}}: 
  module.run:
    - name: state.sls
    - mods: common.oracle.jdk
      {% if not jdk_version == None %}
    - kwargs: {
          pillar: {
            version: {{jdk_version}}
          }   
      }
      {% endif %}
    - unless: test -d /opt/java/jdk{{jdk_version}}

install tomcat {{tomcat_version}} for {{role}}: 
  module.run:
    - name: state.sls
    - mods: common.apache.tomcat
      {% if not tomcat_version == None %}
    - kwargs: {
          pillar: {
            version: {{tomcat_version}}
          }   
      }
      {% endif %}
    - unless: test -d /opt/tomcat/tomcat{{tomcat_version[0]}}

      # INSTALL ANY XXX DEPENDENCIES
      {% if salt['pillar.get'](role_config + ':dependencies') %}
        {% set XXXdepends = salt['pillar.get'](role_config, {})['dependencies'] %}
        {% if XXXdepends != None %}
          {% for dstate,dversion in XXXdepends.iteritems() %}
install {{ dstate }} {{ dversion }} for {{role}}:
  module.run:
    - name: state.sls
    - mods: {{ dstate }}
            {% if not dversion == None %}
    - kwargs: {
          pillar: { 
            version: {{ dversion }},
            dependency: True
          }   
      }   
            {% endif %}
          {% endfor %}
        {% endif %}
      {% endif %}

      {% for i in tomcat_instance %}
# PULL WAR FROM ARTIFACTORY
fetch {{ productname }} source for tomcat instance {{i}}:
        {% if 'mod-package-name' in rolecfgobject %}
          {% set thepackage = salt['pillar.get'](role_config, packagename)['mod-package-name'] %}
        {% else %}
          {% set thepackage = packagename %}
        {% endif %}
  cmd.run:
    - name: |
        echo ***** gettting: {{packagepath}}
        curl {{ packagepath }} -o /opt/tomcat/tomcat{{tomcat_version[0]}}-{{i}}/webapps/{{thepackage}}
        echo ***** downloaded: /opt/tomcat/tomcat{{tomcat_version[0]}}-{{i}}/webapps/{{thepackage}}

        # CALL STATE MODULE TO APPLY PROPERTIES FILES TO THE INSTANCE/xxx dir
apply properties for {{productname}} in tomcat instance {{i}}: 
  module.run:
    - name: state.sls
    - mods: config-properties
    - kwargs: {
          pillar: { 
            tomcat-major-version: {{tomcat_version[0]}},
            role: {{role}}
          }   
      }  
     
      # START TOMCAT
startup tomcat instance {{i}} for {{productname}}:
  cmd.run:
    - name: |
        sudo su tomcat{{tomcat_version[0]}}-{{i}}
        cd /opt/tomcat/tomcat{{tomcat_version[0]}}-{{i}}/bin
        ./startup.sh
    - onlyif: test -f /opt/tomcat/tomcat{{tomcat_version[0]}}-{{i}}/bin/startup.sh

      {% endfor %}
    {% endif %}
  {% endif %}
{% endif %}
