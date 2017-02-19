include:
    - pip


python-gnupg-ng:
    pkg.installed:
        - name: gnupg

    pip.installed:
        - name: gnupg
        - require:
            - pkg: python-gnupg-ng
            - pip: pip
