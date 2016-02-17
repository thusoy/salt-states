ssh-global-known-hosts:
    file.managed:
        - name: /etc/ssh/ssh_known_hosts
        - template: jinja
        - source: salt://ssh/known_hosts


ssh-global-client-configuration:
    file.managed:
        - name: /etc/ssh/ssh_config
        - source: salt://ssh/ssh_config
        - template: jinja
