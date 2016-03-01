hostname-from-id:
    cmd.run:
        - name: hostname {{ grains.id }}
        - unless: hostname | grep "^{{ grains.id }}$"

    file.managed:
        - name: /etc/hostname
        - contents: {{ grains.id }}
