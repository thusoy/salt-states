# Whitelisting of who is authorized to use at (does not actually install at)
# Ref. NSA RHEL 3.4.4

at.deny:
    file.absent:
        - name: /etc/at.deny


at.allow:
    file.managed:
        - name: /etc/at.allow
        - source: salt://hardening/access-control/at.allow
        - template: jinja
