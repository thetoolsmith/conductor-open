include:
  - common.users.appuser

running setup for salty.consul.server: 
  module.run:
    - name: state.sls
    - mods: common.consul.server

