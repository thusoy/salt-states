include:
    - python-pip


python-gnupg-ng:
    pkg.installed:
        - pkgs:
            - gnupg2
            - python-dev

    pip.installed:
        - name: gnupg
        - require:
            - pkg: python-gnupg-ng
