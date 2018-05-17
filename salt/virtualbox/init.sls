virtualbox-deps:
    pkg.installed:
        - name: apt-transport-https


virtualbox:
    pkgrepo.managed:
        - name: deb https://download.virtualbox.org/virtualbox/debian {{ grains['oscodename'] }} contrib
        - key: salt://virtualbox/repo-key.key
        - require:
            - pkg: virtualbox-deps

    pkg.installed:
        - pkgs:
            - virtualbox
        - require:
            - pkgrepo: virtualbox
