include:
    - .
    - .pillar_check


ghost-cli-user:
    user.present:
        - name: ghost-cli
        - system: True
        - shell: /usr/sbin/nologin
        # The user need to be able to run sudo for setup to work
        - groups:
            - sudo
        - password: {{ salt['pillar.get']('ghost-cli:user_password') }}
