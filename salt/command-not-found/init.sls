command-not-found:
    pkg.installed: []

    cmd.wait:
        - name: update-command-not-found
        - watch:
            - pkg: command-not-found
