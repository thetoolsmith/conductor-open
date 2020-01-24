test touch home file:
  file.touch:
    - name: foo.test.file
    - unless: test -f foo.test.file


