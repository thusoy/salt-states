wicd:
    pkg.installed:
        - pkgs:
            - wicd-client
            - wicd-daemon

    init_script.managed:
        - systemd: salt://wicd/wicd-systemd

    # fails to start if the sysV config is present
    file.absent:
        - name: /etc/init.d/wicd
