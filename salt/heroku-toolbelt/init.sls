heroku-toolbelt-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https
            - ruby


heroku-toolbelt:
    pkgrepo.managed:
        - name: deb http://toolbelt.heroku.com/ubuntu ./
        - key_url: salt://heroku-toolbelt/release-key.asc
        - require:
            - pkg: heroku-toolbelt-deps

    pkg.installed:
        - name: heroku-toolbelt

    # Needed to actually install the latest version of the toolbelt
    cmd.wait:
        - name: heroku --version
        - watch:
            - pkg: heroku-toolbelt
