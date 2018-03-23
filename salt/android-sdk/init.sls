{% set version_id = '3859397 sha256=444e22ce8ca0f67353bda4b85175ed3731cae3ffa695ca18119cbacef1c1bea0' %}
{% set version, source_hash = version_id.split() %}

android-sdk-deps:
    pkg.installed:
        - name: unzip

android-sdk:
    group.present:
        - name: android

    file.managed:
        - name: /usr/local/src/sdk-tools-linux-{{ version }}.zip
        - source: https://dl.google.com/android/repository/sdk-tools-linux-{{ version  }}.zip
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: unzip -d /opt/android-sdk /usr/local/src/sdk-tools-linux-{{ version }}.zip &&
                find /opt/android-sdk -type f -perm -u=x -exec chmod 775 {} \; &&
                find /opt/android-sdk -type d -exec chmod 775 {} \; &&
                chown -R :android /opt/android-sdk
        - require:
            - pkg: android-sdk-deps
        - watch:
            - file: android-sdk
