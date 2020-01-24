system.salty:

  salty.system.zk_test:
    zookeeper:
      members: 4
    activemq:
      count: 2

  salty.system.small_test:
    nifi:
      members: default
    activemq:
      count: 1
  salty.system.defaults_test:
    nifi:
      members: default
    activemq:
      count: default

  salty.system.no_defaults_test:
    nifi:
      members: 6
    activemq:
      count: 1

  salty.system.simple_test:
    activemq:
      count: 2

  salty.system.just_cluster_test:
    nifi:
      members: 2

  salty.system.bigger_test:
    nifi:
      members: default
    activemq:
      count: 2

  # this tests all role types. It also tests the role based orch hooks no duplicates role orch state execution when a composite role conatins the same role in the system.
  salty.system.all_role_types_test:
    nifi:
      members: 2
    activemq:
      count: 1
    test-composite:
      count: 1

  salty.system.composite_role_default:
    test-composite:
      count: default

  # THIS TEST VALIDATES THAT WHEN USING COUNT AND MEMBERS ON THE WRONG ROLE TYPE (CLUSTER VS. SINGLE)
  # THE PROVISIONING STILL SUCCEEDS, BUT USES THE DEFAULTS

  # FAILS TEST (non cluster member doesn't use it's default count it still uses members)
  salty.system.invalid_test:
    nifi:
      count: 2
    activemq:
      members: 2


