docker-engine:
    pkgrepo.managed:
        - name: deb https://apt.dockerproject.org/repo debian-{{ grains['oscodename'] }} main
        - keyserver: hkp://keyserver.ubuntu.com:80
        - keyid: 58118E89F3A912897C070ADBF76221572C52609D

    pkg.installed:
        - require:
            - pkgrepo: docker-engine

    service.running:
        - name: docker
