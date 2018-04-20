{% from 'android-sdk/map.jinja' import android_sdk with context %}
{% set version_spec = android_sdk['version_spec'] %}
{% set version, source_hash = version_spec.split() %}
{% set arch = grains['kernel'].lower() %}

android-sdk-deps:
    pkg.installed:
        - name: unzip

android-sdk:
    group.present:
        - name: android

    file.managed:
        - name: /usr/local/src/sdk-tools-{{ arch }}-{{ version }}.zip
        - source: https://dl.google.com/android/repository/sdk-tools-{{ arch }}-{{ version  }}.zip
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: unzip -d /opt/android-sdk /usr/local/src/sdk-tools-{{ arch }}-{{ version }}.zip &&
                find /opt/android-sdk -type f -perm -u=x -exec chmod 775 {} \; &&
                find /opt/android-sdk -type d -exec chmod 775 {} \; &&
                chown -R :android /opt/android-sdk
        - require:
            - pkg: android-sdk-deps
        - watch:
            - file: android-sdk
