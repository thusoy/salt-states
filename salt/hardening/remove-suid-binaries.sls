# Remove obsolete binaries and remove suid bit on unused ones
# Ref. NSA RHEL guide section 2.2.3.4

{% for binary in (
    '/usr/bin/rcp',
    '/usr/bin/rlogin',
    '/usr/bin/rsh',
    ) %}
hardening-remove-obsolote-{{ binary }}:
    file.absent:
        - name: {{ binary }}
{% endfor %}


{% for binary in (
    '/usr/bin/chfn',
    '/usr/bin/chsh',
    '/usr/bin/wall',
    '/usr/bin/write',
    ) %}
hardening-remove-setuid-bit-{{ binary }}:
    file.managed:
        - name: {{ binary }}
        - replace: False
        - mode: 755
{% endfor %}
