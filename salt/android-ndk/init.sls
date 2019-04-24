{% from 'android-ndk/map.jinja' import android_ndk with context %}
{% set version_spec = android_ndk['version_spec'] %}
{% set version, source_hash = version_spec.split() %}
{% set arch = grains['kernel'].lower() %}
{% set install_location = android_ndk.get('install_location', '/opt') %}

android-ndk-deps:
    pkg.installed:
        - name: unzip
        - unless: which unzip


android-ndk:
    group.present:
        - name: android

    file.managed:
        - name: /usr/local/src/android-ndk-{{ version }}-{{ arch }}-x86_64.zip
        - source: https://dl.google.com/android/repository/android-ndk-{{ version }}-{{ arch }}-x86_64.zip
        - source_hash: {{ source_hash }}
        - makedirs: True

    cmd.watch:
        - name: unzip -d {{ install_location }} /usr/local/src/android-ndk-{{ version }}-{{ arch }}-x86_64.zip &&
                find {{ install_location }} -type f -perm -u=x -exec chmod 775 {} \; &&
                find {{ install_location }} -type d -exec chmod 775 {} \; &&
                chown -R :android {{ install_location }}
        - require:
            - pkg: android-ndk-deps
        - watch:
            - file: android-ndk
