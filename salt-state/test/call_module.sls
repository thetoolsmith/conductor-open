testing module execution from state:
  module.run:
    - name: state.sls
    - mods: test.touch_file
    - kwargs: {
          pillar: {
            foo: bar, 
          }   
      }
