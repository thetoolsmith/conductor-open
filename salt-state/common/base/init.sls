# COMMON BASE STATE

common.base.install_requirements:
  cmd.run:
    - name: |
        echo Installing base requirements
        echo Installling easy_install pip
        echo Installing python packages.....

install common.base packages:
  pkg.installed:
    - pkgs: 
      - tree
      - wget
      - lsof
      - unzip
      - pciutils
      - mdadm
           
