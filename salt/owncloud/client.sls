owncloud-client:
    pkgrepo.managed:
        - humanname: ownCloud desktop repo
        - name: deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Debian_{{ grains.osmajorrelease }}.0/ /
        - key_url: salt://owncloud/Release.key

    pkg.installed:
        - name: owncloud-client
        - require:
            - pkgrepo: owncloud-client
