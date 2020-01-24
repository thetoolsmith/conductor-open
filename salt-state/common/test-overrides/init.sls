# test-override common state
{% from "common/test-overrides/map.jinja" import test-overrides with context %}

{% set version = salt['pillar.get']('version', test-overrides['product-version']) %}
{% set product = test-overrides['product-name'] %}
{% set role = salt['pillar.get']('role', product) %} #role passed in pillar, or use product 
{% set other_config = salt['pillar.get']('other-config', test-overrides['other-config']) %} 

test state message for {{role}}:
  cmd.run:
    - name: |
        echo state testing config overriding
        echo test-overrides {{ version }}
        echo other config {{other_config}}
