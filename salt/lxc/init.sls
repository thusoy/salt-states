lxc-container:
    lxc.present:
        - name: meowth
        - running: True
        - template: debian
        - network_profile: jessie
