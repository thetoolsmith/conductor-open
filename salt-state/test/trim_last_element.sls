{% set file_path = '/foo/bar/sub/one/two/myfile' %} 
{% set config = file_path.split('/')|last|join('') %} #from a list to a string back to a list
{% set new_path = '/' + (file_path.split('/') | difference(config))|join('/') %}

test last element in jinja:
  cmd.run:
    - name: |
        echo {{new_path}}

