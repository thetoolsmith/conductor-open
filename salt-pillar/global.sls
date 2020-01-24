#!yaml|gpg

# ########################################################################
#
# THIS PILLAR CONTAINS GLOBAL SCOPE CONFIG
# DATA THAT IS NOT ENVIRONMENT SPECIFIC
#
# PRODUCT VERSION DEFAULTS FOR THE ENVIRONMENTS, SUPPORTED VERSIONS ETC...
# THESE CAN BE OVERIDE WHEN APPLY STATE FILES
##########################################################################
global:

  domain_suffix: ".foobar.com"

  salt-minion:
    version: 2017.7.8

  default-startup: new-instance.sls

  # ARTIFACTORY SPECIFICS
  artifactory:
    protocol: http
    host: artifactory.orgX.com
    port: 8081
    user: |
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v2.0.22 (GNU/Linux)

      hIwDndYGtYR5UKMBBACjbx7M+mgXswn9Xu/rjYOEYI4qRhsEZpt7SPanM+6tC8IJ
      X5TdXiSSYZx/zs3a0kYSDFpGfuuKjYIZFwiM/63gh+yfg14WyU9UCJ9YxBaPwL7k
      g7uvrsb6B75dv3ybCoL61PhmWLsqsm4V31L71m2F03PapX7Kz0HALvLC6QftiNJF
      AVGciDnSP9Jiq2j0nipDoAlf+LTLrQijyE1Zoqs7Fai9VZe7cUh2sDXidVunRya1
      XAiaM6yfOrnK/dUeTyPifa5QLubp
      =/J11
      -----END PGP MESSAGE-----

    token: |
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v2.0.22 (GNU/Linux)

      hIwDndYGtYR5UKMBA/4gxcfhcEvnP6F93DU+gyqn5o5Hzre0i5eyEmmeWch0/z7x
      JL3XLrpl2mbD7RMjLKXcvMx38FkVK5/tTcnEuCe5nXtJbUgjzBG5EidA/3ob3MWo
      mLhLg69EL297C9EnaRisaPPv5tmmdbSpRNdUFtiaJ29S6HmEQ8mPcrwUR0yjANJW
      AcUibgWBpudcWJBDLOQ32mDji6nThQSDK8yfm6h9bgTWgipl0TkDdK7TU8cH2g+w
      rRUjKa/yaiYn1sMYMkkx2pEbUPDd5XtL4P+vitL3ZqTNoX/qQbo=
      =/aKX
      -----END PGP MESSAGE-----

    repo-path: /artifactory/libs-release-local
    path: /artifactory


  # DEFINE REPORTING TYPES AVAILABLE IN CUSTOM stats MODULE
  stats-reporting:
    metric:
      memory: True
      processes: False
    recipients:
      - paul@acidhousetracks.com
      - acidhousetracks@gmail.com


  # HASH MAP PROVIDES ENFORCEMENT ONLY SUPPORTED VERSIONS IF WE ARE PULLING FROM ARTIFACTORY IN THE STATE
  # WHEN A NEW VERSION IS NEEDED, ADD TO THE LIST.
  # IF LOWER LEVEL PILLAR OVERRIDES, THE HASH KEY WILL BE CHECKED HERE.
  # ARTIFACTORY HAS 3 ARTIFACT CHECKSUMS. MD5, SHA-1, SHA-256. MD5 only is supported. MAY ADD OTHERS IN FUTURE

  alertlogic:
    agent:
      supported-versions:
        2.6.0:
          package: al-agent-2.6.0-1.x86_64.rpm
          md5: 79a352a55dc5630e54599b4b86a358d4
  datastax:
    opscenter:
      supported-versions:
        6.5.3:
          package: opscenter-6.5.3
          md5:

  apache:
    activemq:
      repo-path: /artifactory/libs-release-local/com/apache/activemq/
      supported-versions:
        5.14.4: 
          package: apache-activemq-5.14.4-bin.tar.gz
          md5: 6b2906883409187fa2f0b228b729f637
        5.15.5:
          package: apache-activemq-5.15.5-bin.tar.gz
          md5: 70440193e7c924b4ca885b6a37e6639f
    # NOT GETTING FROM ARTIFACTORY, WAITING TO CREATE NEW REPO STRUTCURE
    zookeeper:
      repo-path: /artifactory/libs-release-local/com/apache/zookeeper/
      supported-versions:
        3.5.2-alpha: 
          package: zookeeper-3.5.2-alpha.tar.gz 
          md5: 
        3.4.10: 
          package: zookeeper-3.4.10.tar.gz 
          md5: 

    cassandra:
      repo-path: /artifactory/libs-release-local/com/apache/cassandra/
      supported-versions:
        3.11.2: 
          package: apache-cassandra-3.11.2-bin.tar.gz
          md5: 1c1bc0b216f308500e219968acbd625e
        dse-6.0.2:
          package: dse-full-6.0.2

    nifi:
      repo-path: /artifactory/libs-release-local/com/apache/nifi/
      supported-versions:
        1.5.0: 
          package: nifi-1.5.0-bin.tar.gz
          md5: 3a74c126e81ba88f0aedf49c395ff5d1
    # GETTING FROM ARTIFACTORY, BUT NEED TO CHANGE REPO ONCE NEW STRUCTURE IS IN PLACE
    kafka:
      repo-path: /artifactory/libs-release-local/com/apache/kafka/
      supported-versions:
        confluent-4.0.0: 
          package: confluent-oss-4.0.0-2.11.tar.gz
          md5: 21179efb90512ca0c0651481ce4a5f27
        2.0.0: 
          package: kafka-2.0.0-src.tgz
          md5: 0780a2f3f7f5e3d6f42dad0bf7e58947
        2.11-2.0.0:
          package: kafka_2.11-2.0.0.tgz
          md5: 97f1a21b8dc5782503488e85adf1b061
    tomcat:
      instances: 10
      instance-config:
        base:
          shutdown-port: 8000
          connector-port: 8080
          ssl-redirector-port: 8440
          ajp-port: 8110
          jmx-port: 9100

      # ALL ABOVE ARE +1 FOR EACH INSTANCE IN SUCCESSION, SO WE DON'T NEED A CONFIG FOR EACH
      server.xml-updates:
        shutdown-port: 
          pattern: '<Server port="8005" shutdown="SHUTDOWN">'
          replace: '<Server port="REPLACE_ME" shutdown="SHUTDOWN">' 
        connector-port:
          pattern: '<Connector port=\"8080\" protocol=\"HTTP/1.1\"'
          replace: '<Connector port="REPLACE_ME" protocol="HTTP/1.1"'
        ssl-redirector-port:
          pattern: '               redirectPort="8443" />'
          replace: '               redirectPort="REPLACE_ME" />'
        ajp-port: 
          pattern: '<Connector port="8009" protocol="AJP/1.3"'
          replace: '<Connector port="REPLACE_ME" protocol="AJP/1.3"'

      repo-path: /artifactory/ext-release-local/com/apache/tomcat/
      supported-versions:
        8.0.39: 
          package: apache-tomcat-8.0.39.tar.gz
          md5: 529c26b1987e2bd5e04785ef7c814271
        8.5.6:
          package: apache-tomcat-8.5.6.tar.gz
          md5: e273e27deb1828ae5f19374616b9fba8
        
  oracle:
    client:
      repo-path: /artifactory/ext-release-local/com/oracle/client/
      supported-versions:
        11.2.0.4.0-1: 
          package: oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
          sqlplus_package: oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm
          md5: f184649f85840cef2ed2e6a4d52b9647
    java:
      repo-path: /artifactory/libs-release-local/com/oracle/jdk/
      supported-versions:
        1.7.0:
          package: java-1.7.0-openjdk
          md5:
        1.8.0_101: 
          package: jdk-8u101-linux-x64.tar.gz
          md5: a7ab8014716b0dac3adcaf5342167699
        1.8.0_181:
          package: jdk-8u181-linux-x64.tar.gz
          md5: ef599e322eee42f6769991dd3e3b1a31
         
  liquibase-core:
    repo-path: /artifactory/ext-release-local/com/liquibase/core/
    supported-versions:
      3.5.3: 
        package: liquibase-3.5.3-bin.zip
        md5: 94f3bd06fde9d1c828e55da884ddde55

  # USE THIS YAML BLOCK FOR GLOBAL FLAGS IN CONDUCTOR CORE CODE. EXAMPLE TO OPTIONALLY SKIP ORCH HOOKS
  # FOR A PARTICULAR PRODUCT GROUP ON A DESTROY ACTION
  conductor:
    devops:
      skip-hooks-on-destroy: true
  

  # USE THIS MAP FOR SERVICES THAT DO NOT HAVE SCRIPT IN /etc/init.d BUT NEED TO BE MANAGED
  # BY GENERIC salt://common/stop and start states
  managed-services:
    nifi: nifi
    activemq: /opt/activemq/apache-activemq-5.15.5/bin/activemq

