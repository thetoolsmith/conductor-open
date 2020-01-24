{% set file_path = '/foo/bar/sub/one/two/myfile' %} 
{% set config = file_path.split('/')|last %}
test last element in jinja:
  cmd.run:
    - name: |
        echo {{config}}

