owncloud-client-deps:
    pkg.installed:
        - name: apt-transport-https


owncloud-client:
    pkgrepo.managed:
        - humanname: ownCloud desktop repo
        - name: deb https://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Debian_{{ grains.osmajorrelease }}.0/ /
        - key_url: salt://owncloud/Release.key
        - require:
            - pkg: owncloud-client-deps

    pkg.installed:
        - name: owncloud-client
        - require:
            - pkgrepo: owncloud-client
