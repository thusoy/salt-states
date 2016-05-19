# Whitelisting of who is authorized to use at (does not actually install at)
# Ref. NSA RHEL 3.4.4

hardening.access-control.at.deny:
    file.absent:
        - name: /etc/at.deny


hardening.access-control.at.allow:
    file.managed:
        - name: /etc/at.allow
        - source: salt://hardening/access-control/at.allow
        - template: jinja
