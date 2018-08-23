include:
    - .
    - .pillar_check


ghost-cli-user:
    file.directory:
        - name: /var/www

    user.present:
        - name: ghost-cli
        - system: True
        - shell: /usr/sbin/nologin
        - home: /var/www/ghost
        # The user need to be able to run sudo for setup to work
        - groups:
            - sudo
        - password: {{ salt['pillar.get']('ghost-cli:user_password') }}
        - require:
            - file: ghost-cli-user
