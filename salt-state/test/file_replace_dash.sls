test file replace text with dash: 
  file.replace:
    - name: /tmp/foo
    - pattern: "- /var/lib/cassandra/data.*$"
    - repl: "- /other/cassandra/data"
    - backup: .bak
