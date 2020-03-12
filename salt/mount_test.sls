mount-/tmp:
    mount.mounted:
        - name: /tmp
        - device: tmpfs
        - fstype: tmpfs
        - opts:
            - defaults
            - nodev
            - noexec
            - nosuid
            - size=1G

mount-/var/tmp:
    mount.mounted:
        - name: /var/tmp
        - device: /tmp
        - fstype: none
        - opts:
            - bind
