{% from "common/map.jinja" import common with context %}
{% from "common/apache/zookeeper/map.jinja" import zookeeper with context %}

{% set dest_path = salt['pillar.get']('dest-path', zookeeper['dest-path']) %}
{% set product = salt['pillar.get']('product', zookeeper['product-name']) %}
{% set user = salt['pillar.get']('user', zookeeper['user']) %}
{% set user_home = '/home/' + user %}
{% if user == 'root' %}
  {% set user_home = '/' + user %}
{% endif %}

{% if (not product == None) and (not dest_path == None) and (not user == None) %}

  {% set config = 'zkServer.sh' %}
configure {{ product }} service:
  cmd.run:
    - name: |
        sed -i 's|#!/usr/bin/env bash|#!/usr/bin/env bash\n# description: Zookeeper Start Stop Restart\n# processname: zookeeper\n# chkconfig: 244 30 80|g' {{config}}
        sed -i 's|ZOOBIN=\"${BASH_SOURCE-$0}\"|source '{{user_home}}'/.bash_profile\nZOOSH=`readlink $0`|g' {{config}}
        sed -i 's/ZOOBIN=\"$(dirname \"${ZOOBIN}\")\"/ZOOBIN=`dirname $ZOOSH`/g' {{config}}
        sed -i 's/ZOOBINDIR=\"$(cd \"${ZOOBIN}\"; pwd)\"/ZOOBINDIR=`cd $ZOOBIN; pwd`\nZOO_LOG_DIR=`echo $ZOOBIN`/g' {{config}}
    - cwd: {{ dest_path }}/zookeeper/bin

create {{product}} service symlink on {{grains['id']}}:
  cmd.run:
    - name: |
        ln -s {{ dest_path }}/zookeeper/bin/{{config}} /etc/init.d/zookeeper
    - unless: test -f /etc/init.d/zookeeper
    - cwd: {{ dest_path }}/zookeeper/bin

enable boot for {{product}} service:
  cmd.run:
    - name: |
        chkconfig zookeeper on

  {% set skip = salt['file.search'](dest_path + '/zookeeper/bin/zkCli.sh', 'source ' + user_home + '/.bash_profile') %}
  {% if not skip %}
configure {{product}} cli on {{grains['id']}}:
  file.replace:
    - name: {{dest_path}}/zookeeper/bin/zkCli.sh
    - pattern: '^#!/usr/bin/env bash.*$'
    - repl: '#!/usr/bin/env bash\nsource {{user_home}}/.bash_profile\n'
    - backup: .bak
  {% endif %}

{% else %}

missing configuration {{product}} abort:
  cmd.run:
    - name: |
        {% for k,v in {'dest-path': dest_path, 'product': product, 'user': user}.iteritems() %}
        echo {{k}} = {{v}}
        {% endfor %}
  module.run:
    - name: test.false
{% endif %}


