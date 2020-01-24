
wait_for_service_to_be_healthy:
  loop.until:
    - name: service.status
    - condition: m_ret == 0
    - period: 5
    - timeout: 20
    - m_args: 
      - zookeeper
    - m_kwargs:
        sig: zookeeper
