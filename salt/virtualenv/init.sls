include:
    - pip


virtualenv:
    pip.installed:
        - name: virtualenv
        - require:
            - pip: pip
