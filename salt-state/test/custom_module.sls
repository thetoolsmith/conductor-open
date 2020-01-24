# ###########################################
# TEST STATE TO SHOW HOW TO EXECUTE FUNCTIONS 
# WITHIN CUSTOM BUILT EXECUTION MODULES, OR
# ANY SALT EXECUTION MODULE 
# ###########################################

testing custom execution module invocation:
  module.run:
    - name: stats.show_memory
    - fpath: /tmp
    - env: test

