unity:
    file.managed:
        - name: /opt/Unity-{{ grains.version }}.pkg
        - source: https://netstorage.unity3d.com/unity/{{ grains.hash }}/MacEditorInstaller/Unity-{{ grains.version }}.pkg
        - source_hash: {{ grains.source_hash }}
    cmd.watch:
        - name: cd /opt &&
                /usr/sbin/installer -verbose -pkg Unity-{{ grains.version }}.pkg -target /
        - watch:
            - file: unity

