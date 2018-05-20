{% set dropbox = pillar.get('dropbox', {}) %}
{% set helper_version = dropbox.get('helper_version_spec', '2015.10.28 sha256=f9780cce3725ee307cdad8a835300e89483504059d302b3c6f91fe5cac0a5411') %}
{% set helper_version, helper_version_hash = helper_version.split() %}

dropbox:
    file.managed:
        - name: /usr/local/src/dropbox-{{ helper_version }}.deb
        - source: https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_{{ helper_version }}_amd64.deb
        - source_hash: {{ helper_version_hash }}

    cmd.wait:
        - name: dpkg -i /usr/local/src/dropbox-{{ helper_version }}.deb
        - watch:
            - file: dropbox
