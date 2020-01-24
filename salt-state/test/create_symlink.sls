test create link:
  file.symlink:
    - name: /tmp/test_sym_link_in_salt
    - target: /usr/bin
    - unless: /tmp/test_sym_link_in_salt

