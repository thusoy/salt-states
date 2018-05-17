{% set owncloud = pillar.get('owncloud', {}) %}
{% set release = owncloud.get('release', 'stable') %}

owncloud:
    pkgrepo.managed:
        - humanname: ownCloud desktop repo
        - name: deb https://download.owncloud.org/download/repositories/{{ release }}/Debian_8.0/ /
        - key_url: salt://owncloud/Release.key
        - gpgkey: salt://owncloud/Release.key

    # pkg.installed:
    #     - name: owncloud-client
    #     - require:
    #         - pkgrepo: owncloud-client
