{% set version_info = pillar.get('unity', {}).get('version_info', '2018.2.6f1 c591d9a97a0b sha256=c57df491262586407aff9555db6df7f019afc85c019fc5dbf1fc5d1930754748') %}
{% set version, version_hash, source_hash = version_info.split() %}

unity:
    file.managed:
        - name: /opt/Unity-{{ version }}.pkg
        - source: https://netstorage.unity3d.com/unity/{{ hash }}/MacEditorInstaller/Unity-{{ version }}.pkg
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: cd /opt &&
                /usr/sbin/installer -verbose -pkg Unity-{{ version }}.pkg -target /
        - watch:
            - file: unity

