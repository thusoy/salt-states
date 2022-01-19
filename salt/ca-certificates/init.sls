ca-certificates:
    pkg.latest


# Remove the expired Let's Encrypt root cert
ca-certificates-lets-encrypt-root-fix:
    file.replace:
        - name: /etc/ca-certificates.conf
        - pattern: 'mozilla/DST_Root_CA_X3.crt'
        - repl: '!mozilla/DST_Root_CA_X3.crt'

    cmd.watch:
        - name: update-ca-certificates
        - watch:
            - file: ca-certificates-lets-encrypt-root-fix
