owncloud-client-deps:
    pkg.installed:
        - name: apt-transport-https


owncloud-client:
    pkgrepo.managed:
        - humanname: ownCloud desktop repo
        - name: deb https://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Debian_{{ grains.osmajorrelease }}.0/ /
        # The key varies with os version, thus download dynamically instead of pinning in the state
        - key_url: https://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Debian_{{ grains.osmajorrelease }}.0/Release.key
        - require:
            - pkg: owncloud-client-deps

    pkg.installed:
        - name: owncloud-client
        - require:
            - pkgrepo: owncloud-client
