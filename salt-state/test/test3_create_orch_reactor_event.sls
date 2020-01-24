# MINION SIDE TEST EVENT TRIGGER STATE
# FIRST LINE DENOTES THE event tag
orch/common/runner_reactor_test3:
  event.send:
    - data:
        role: {{grains['role']}}
        file_name: "BLABLABLA"
