test missing configuration:
  cmd.run:
    - name: |
        {% for k,v in {'file-path': '/tmp', 'product': 'theproduct', 'user': 'theuser'}.iteritems() %}
        echo {{k}} = {{v}}
        {% endfor %}
  module.run:
    - name: test.false
