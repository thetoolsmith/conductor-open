{% set test = ['one', 'two', 'three'] %}

{% set ctr = [1] %}

{% for i in test %}
  {% if ctr[0] == (test|length) %}
debug message test increment off {{i}}:
  cmd.run:
    - name: |
        echo TEST OFF BY ONE
  {% else %}
next element {{i}}:
  cmd.run:
    - name: |
        echo element {{i}}
    {% do ctr.append(ctr.pop() + 1) %}
  
  {% endif %}

{% endfor %}

debug completed test increment:
  cmd.run:
    - name: |
        echo counter is {{ctr}}
        echo counter element 0 is {{ctr[0]}}

