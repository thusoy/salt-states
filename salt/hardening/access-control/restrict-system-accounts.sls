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
        - name: cat /etc/passwd |
                while read line; do
                    user=$(echo "$line" | cut -d":" -f1);
                    uid=$(echo "$line" | cut -d":" -f3);
                    shell=$(echo "$line" | cut -d":" -f7);
                    if [ "$uid" -lt "1000" ] &&
                       [ "$uid" -ne "0" ] &&
                       [ "$user" != "postgres" ] &&
                       [ "$shell" != "/usr/sbin/nologin" ] &&
                       [ "$shell" != "/bin/false" ]; then
                        echo "Removing $shell from $user";
                        usermod -s /usr/sbin/nologin "$user";
                    fi;
                done
