hostname-from-id:
    cmd.run:
        - name: hostname {{ grains.id }}
        - unless: hostname | grep "^{{ grains.id }}$"

    file.managed:
        - name: /etc/hostname
        - contents: {{ grains.id }}

    host.present:
        - name: {{ grains.id }}
        - ips:
            - 127.0.0.1
            - 127.0.1.1
