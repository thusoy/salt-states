{% set version_info = pillar.get('unity', {}).get('version_info', '2018.2.6f1 c591d9a97a0b sha256=b6b717d6c02f88eef5efad2e22afffec0e717f983312308255b8adb733bfce17') %}
{% set version, version_hash, source_hash = version_info.split() %}

include:
    - .

unity-ios:
    file.managed:
        - name: /opt/UnitySetup-iOS-Support-for-Editor-{{ version }}.pkg
        - source: https://netstorage.unity3d.com/unity/{{ version_hash }}/MacEditorTargetInstaller/UnitySetup-iOS-Support-for-Editor-{{ version }}.pkg
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: cd /opt &&
                /usr/sbin/installer -verbose -pkg UnitySetup-iOS-Support-for-Editor-{{ version }}.pkg -target /
        - watch:
            - file: unity-ios

