locales:
    file.managed:
        - name: /etc/locale.gen
        - source: salt://locale/locale.gen
        - template: jinja

    cmd.wait:
        - name: locale-gen
        - watch:
            - file: locales


system-locale:
    locale.system:
        - name: en_US.UTF-8
        - require:
            - cmd: locales
