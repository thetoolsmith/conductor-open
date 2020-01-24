# multi task ID example

doing some stuff:
  user.present:
    - name: foo
    - uid: 888
    - gid: 888
    - home: /home/foo
    - shell: /bin/nologin
    - require:
      - group: foo
  group.present:
    - name: foo
    - gid: 888
  cmd.run:
    - names:
      - echo testing multiple actions in single ID
