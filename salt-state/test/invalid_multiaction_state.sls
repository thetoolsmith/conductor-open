# demonstrate invalid state
# salt compiles all state into python object, so 
# duplicate module calls within a single ID (doing some stuff, is the id)
# are not allowed.

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
      - echo demo invalid state

  cmd.run:
    - names:
      - echo this state will not compile

  module.run:
    - name: state.sls
    - mods: a_state

  module.run:
    - name: state.sls
    - mods: another_state
