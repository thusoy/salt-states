{% from 'android-sdk/map.jinja' import android_sdk with context %}
{% set version_spec = android_sdk['version_spec'] %}
{% set version, source_hash = version_spec.split() %}
{% set arch = grains['kernel'].lower() %}
{% set install_location = android_sdk.get('install_location', '/opt') %}

android-sdk-deps:
    pkg.installed:
        - name: unzip
        - unless: which unzip


android-sdk:
    group.present:
        - name: android

    file.managed:
        - name: /usr/local/src/sdk-tools-{{ arch }}-{{ version }}.zip
        - source: https://dl.google.com/android/repository/sdk-tools-{{ arch }}-{{ version  }}.zip
        - source_hash: {{ source_hash }}
        - makedirs: True

    cmd.watch:
        - name: unzip -d {{ install_location }}/android-sdk /usr/local/src/sdk-tools-{{ arch }}-{{ version }}.zip &&
                find {{ install_location }}/android-sdk -type f -perm -u=x -exec chmod 775 {} \; &&
                find {{ install_location }}/android-sdk -type d -exec chmod 775 {} \; &&
                chown -R :android {{ install_location }}/android-sdk
        - require:
            - pkg: android-sdk-deps
        - watch:
            - file: android-sdk
