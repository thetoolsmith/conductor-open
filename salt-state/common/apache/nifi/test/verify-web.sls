# TEST NIFI LOCAL WEB APPLICATION
{% from "common/map.jinja" import common with context %}
{% from "common/apache/nifi/map.jinja" import nifi with context %}

{% set dest_path = salt['pillar.get']('dest-path', nifi['dest-path'] + '/nifi/' + nifi['product-version']) %}
{% set ipaddr = salt['grains.get']('ipv4')[0] %}

test.wait for service nifi web app:
  cmd.run: 
    - name: |
        date
        sleep 20

test.verify nifi web app:
  cmd.run: 
    - name: |
        date
        wget -p http://{{ipaddr}}:8080/nifi -O /tmp/test

