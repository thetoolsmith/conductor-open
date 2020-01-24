# TEST UPDATING BASHRC
test update bashrc environment on {{grains['id']}}:
    file.append:
      - name: /root/.bashrc
      - text: |
          export FOOBAR=/opt/bla/bla
          export FOOBAR_EXEC='"$FOOBAR/bin"'
          export PATH='"$FOOBAR_EXEC:$PATH"
      - template: jinja

