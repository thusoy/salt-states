spotify:
    pkgrepo.managed:
        - name: deb http://repository.spotify.com stable non-free
        - humanname: Spotify desktop client repo
        - keyid: 0DF731E45CE24F27EEEB1450EFDC8610341D9410
        - keyserver: hkp://keyserver.ubuntu.com:80

    pkg.installed:
        - name: spotify-client
        - require:
            - pkgrepo: spotify
