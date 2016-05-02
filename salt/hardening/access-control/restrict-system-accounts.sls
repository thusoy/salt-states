# Ref. NSA RHEL 2.3.1.4

{% for user in (
    'bin',
    'sys',
    'sync',
    'games',
    'lp',
    'news',
    'uucp',
    'www-data',
    'backup',
    'list',
    'irc',
    'gnats',
    'colord',
    'dnsmasq',
    'pulse',
    'saned',
    'usbmux',
    'uuidd',
    ) %}
hardening-remove-unused-system-account-{{ user }}:
    user.absent:
        - name: {{ user }}
{% endfor %}


hardening-remove-system-account-login-shells:
    cmd.run:
        - name: |
            import subprocess
            vulnerable_accounts = []
            with open('/etc/passwd') as fh:
                for line in fh:
                    fields = line.strip().split(':')
                    user, uid, shell = fields[0], fields[2], fields[6]
                    if 0 < int(uid) < 1000 and user != 'postgres' and shell not in ('/usr/sbin/nologin', '/bin/false'):
                        vulnerable_accounts.append(user)
                        subprocess.call(['usermod', '-s', '/usr/sbin/nologin', user])
            if vulnerable_accounts:
                print('changed=yes comment="Removed login shell for %s"' % ', '.join(vulnerable_accounts))
        - stateful: True
        - shell: /usr/bin/python
