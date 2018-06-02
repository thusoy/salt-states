heroku-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https


heroku:
    pkgrepo.managed:
        - name: deb https://cli-assets.heroku.com/apt ./
        - key_url: salt://heroku/release-key.asc
        - require:
            - pkg: heroku-deps

    pkg.installed:
        - name: heroku
        - require:
            - pkgrepo: heroku
