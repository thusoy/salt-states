include:
    - apt-transport-https


kubectl:
    pkgrepo.managed:
        # There's no dedicated repo for buster yet (there is one for stretch
        # but it doesn't work), but since it's just a static binary it doesn't
        # make any difference.
        - name: deb https://apt.kubernetes.io/ kubernetes-xenial main
        - key_url: salt://kubectl/release-key.asc

    pkg.installed:
        - name: kubectl
        - require:
            - pkgrepo: kubectl
