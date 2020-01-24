include:
  - common.users.appuser

running setup for devops.consul.server: 
  module.run:
    - name: state.sls
    - mods: common.consul.server

