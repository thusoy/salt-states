# Ref. NSA RHEL 2.3.1.2

hardening-access-control-restrict-su:
    file.append:
        - name: /etc/pam.d/su
        - text: auth required pam_wheel.so
