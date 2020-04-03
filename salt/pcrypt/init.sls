pcrypt-deps:
    pkg.installed:
        - name: python-virtualenv


pcrypt:
    virtualenv.managed:
        - name: /opt/venvs/pcrypt
        - requirements: salt://pcrypt/requirements.txt
        - require:
            - pkg: pcrypt-deps

    file.symlink:
        - name: /usr/local/bin/pcrypt
        - target: /opt/venvs/pcrypt/bin/pcrypt
