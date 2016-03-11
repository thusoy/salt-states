spotify:
    pkgrepo.managed:
        - name: deb http://repository.spotify.com stable non-free
        - humanname: Spotify desktop client repo
        - keyid: BBEBDCB318AD50EC6865090613B00F1FD2C19886
        - keyserver: hkp://keyserver.ubuntu.com:80

    pkg.installed:
        - name: spotify-client
        - require:
            - pkgrepo: spotify
