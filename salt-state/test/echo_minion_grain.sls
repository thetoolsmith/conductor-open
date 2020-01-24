test echo minion grain: 
  cmd.run:
    - name: |
        echo {{grains['ipv4'][0]}} {{grains['id']}}
