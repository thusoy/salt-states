yarn-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https


yarn:
    pkgrepo.managed:
        - name: deb https://dl.yarnpkg.com/debian/ stable main
        - key_url: salt://yarn/repo-key.gpg
        - require:
            - pkg: yarn-deps

    pkg.installed:
        - require:
            - pkgrepo: yarn
