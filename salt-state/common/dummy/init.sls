# dummy state does nothing
# allows provisoning a vanilla vm using the conductor

the common dummy state:
  cmd.run:
    - name: |
        echo common dummy does nothing
