{% set g = 'foobar' %}
{% set v = '\"test grain set in state\"' %}

test setting grain in state:
  module.run:
    - name: grains.set
    - key: 'foobar'
    - val: 'testing setting grain from state module'

test get new grain via module:
  module.run:
    - name: grains.get
    - key: 'foobar'
