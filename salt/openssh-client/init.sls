openssh-client:
    pkg.installed: []

    file.managed:
        - name: /etc/ssh/ssh_config
        - source: salt://openssh-client/ssh_config
        - template: jinja


openssh-client-global-known-hosts:
    file.managed:
        - name: /etc/ssh/ssh_known_hosts
        - template: jinja
        - source: salt://openssh-client/known_hosts
