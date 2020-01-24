require_check1:
  module.run:
    - name: state.sls
    - mods: utility.supported_version
    - require_in:
      - cmd: require_check
    - kwargs: {
          pillar: {
            version: '5.15.5', 
            product: 'activemq',
            pillarpath: 'config.common:apache'
          }   
      }         
require_check:
  cmd.run:
    - name: |
        echo FIRST

