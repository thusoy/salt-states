{% set version_info = pillar.get('unity', {}).get('version_info', '2018.2.6f1 c591d9a97a0b sha256=be27982c29ac6f2a0d6a86591055069e11e77ed346093e6aed8681c7b7320461') %}
{% set version, version_hash, source_hash = version_info.split() %}

include:
    - .

unity-android:
    file.managed:
        - name: /opt/UnitySetup-Android-Support-for-Editor-{{ version }}.pkg
        - source: https://netstorage.unity3d.com/unity/{{ version_hash }}/MacEditorTargetInstaller/UnitySetup-Android-Support-for-Editor-{{ version }}.pkg
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: cd /opt &&
                /usr/sbin/installer -verbose -pkg UnitySetup-Android-Support-for-Editor-{{ version }}.pkg -target /
        - watch:
            - file: unity-android

