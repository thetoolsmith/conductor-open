# SALTY SUMOLOGIC - INIT SUMO COLLECTOR CONFIG STATE
# user and group are optional pillar parameters

{% import_yaml "common/sumologic/defaults.yaml" as defaults %}

{% set user = salt['pillar.get']('user', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set group = salt['pillar.get']('group', salt['pillar.get']('ami-user-map:' + grains['os'], 'root' )) %}
{% set dest_path = salt['pillar.get']('dest-path', defaults.sumologic['dest-path']) %}

# NOT SURE WHAT ALL THIS IS ABOUT, BUT TAKEN RIGHT FROM 
# https://github.orgXlive.com/orgX-Corporation/DataLake-Tools/blob/development/infracode/datalake/terraform/base_scripts/scripts/config_hosts.sh#L146-L157
initialize sumologic on {{grains['id']}} for {{grains['role']}}:
  cmd.run:
    - name: |
        ./SumoCollector.sh -q -varfile {{dest_path}}/sumo_credentials.txt
        chown -R {{user}}:{{group}} /{{dest_path.split('/')[1]}}/SumoCollector
    - cwd: /home/{{user}}/sumo

install sumologic collector on {{grains['id']}} for {{grains['role']}}:
  cmd.run:
    - name: |
        ./collector remove
        sed -i "s:#RUN_AS_user=:RUN_AS_user={{user}}:" collector
        ./collector install
        echo 'cutoffRelativeTime="-1h" >> config/user.properties'
        ./collector restart
        echo 'DEBUG: Done configuring sumologic agent'
    - cwd: /opt/SumoCollector

# NOTES: 
# this was taken from datalake install 
# https://github.orgXlive.com/orgX-Corporation/DataLake-Tools/blob/development/infracode/datalake/terraform/base_scripts/scripts/config_hosts.sh#L146-L157
# need to review whats dl specific and wether these actions would always be desired on any sumologic deployment
# if these become common, then cutoffRelativeTime might be product group specfic, in which case make it a pillar override

