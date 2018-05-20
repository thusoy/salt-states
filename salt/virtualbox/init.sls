virtualbox-deps:
    pkg.installed:
        - name: apt-transport-https


virtualbox:
    pkgrepo.managed:
        - name: deb https://download.virtualbox.org/virtualbox/debian {{ grains.oscodename }} contrib
        - key_url: salt://virtualbox/release-key.asc
        - require:
            - pkg: virtualbox-deps

    pkg.installed:
        - pkgs:
            - linux-headers-amd64
            - virtualbox
            - virtualbox-dkms
        - require:
            - pkgrepo: virtualbox
