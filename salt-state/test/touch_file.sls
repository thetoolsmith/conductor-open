{% set foo = salt['pillar.get']('foo', 'nothing passed') %} 

# *** this is why its not good to use this syntax where the id is the actual name parameter value of the module. This fails.
#/var/log/foo.empty:
#  file.touch
#    - unless: test -f /var/log/foo.empty


create the file:
  file.touch:
    - name: /var/log/foo.empty
    - unless: test -f /var/log/foo.empty

test update that file now:
  file.append:
    - name: /var/log/foo.empty
    - text: |
        writing dynamic pillar to file {{ foo }}
    - onlyif: test -f /var/log/foo.empty


#tests.testupdate tomcat server xml:
#  file.replace:
#    - name: /opt/tomcat/conf/server.xml
#    - pattern: 'Connector port="8080"'
#    - repl: 'Connector port="80"'
#    - backup: .bak

