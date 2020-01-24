{% set thisstring = '/opt/Foo' %}
{% set test_path = thisstring.split('/')[1] %}
test jinja split string:
  cmd.run:
    - name: |
        echo .... {{test_path}} ....

