start state zookeeper on {{grains['id']}}:
  module.run:
    - name: service.start
    - m_name: zookeeper

