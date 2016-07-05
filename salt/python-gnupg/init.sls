include:
    - pip

python-gnupg:
    pkg.installed:
        - name: gnupg

    pip.installed:
        - name: gnupg
        - require:
            - pkg: python-gnupg
            - pip: pip
