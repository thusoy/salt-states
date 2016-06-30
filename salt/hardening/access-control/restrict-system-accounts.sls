#!py
# Ref. NSA RHEL 2.3.1.4

import subprocess
import collections
import pwd

DEFAULT_UNUSED_SYSTEM_ACCOUNTS = set([
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
])


def run():
    states = {}
    for name, state in remove_unused_system_accounts():
        states[name] = state
    for name, state in remove_system_account_login_shells():
        states[name] = state
    return states


def remove_unused_system_accounts():
    whitelisted_accounts = get_whitelisted_system_accounts()
    unused_system_accounts = DEFAULT_UNUSED_SYSTEM_ACCOUNTS - whitelisted_accounts
    for account in unused_system_accounts:
        yield 'hardening-remove-unused-system-account-' + account, {
            'user.absent': [
                {'name': account},
            ]
        }


def get_whitelisted_system_accounts():
    whitelist = set([])
    try:
        pillar_get = __salt__['pillar.get']
        whitelist = set(pillar_get('hardening:whitelisted_accounts', []))
    except NameError:
        pass
    return whitelist



def remove_system_account_login_shells():
    whitelisted_system_login_shell_accounts = []
    for user, shell in get_system_account_shells():
        # Allow both /bin/false and /usr/sbin/nologin to prevent unnecessary changes
        valid_shells = ('/usr/bin/false', '/bin/false', '/usr/sbin/nologin')
        target_shell = shell if shell in valid_shells else '/usr/sbin/nologin'
        yield 'hardening-remove-system-account-login-shells-' + user, {
            'user.present': [
                {'name': user},
                {'shell': target_shell}
            ]
        }


def get_system_account_shells():
    boundaries = get_account_boundaries()
    for account in pwd.getpwall():
        username = account.pw_name
        shell = account.pw_shell
        if is_system_account(account.pw_uid, boundaries):
            yield username, shell


def is_system_account(uid, boundaries):
    # If sys_uid_min and sys_uid_max is specified, check that it's within those ranges,
    # otherwise check that 0 < uid < uid_min
    sys_uid_min = boundaries.get('sys_uid_min')
    sys_uid_max = boundaries.get('sys_uid_max')
    uid_min = boundaries.get('uid_min', 1000)
    if sys_uid_min and sys_uid_max:
        return sys_uid_min <= uid <= sys_uid_max
    return 0 < uid < uid_min


def get_account_boundaries():
    rv = {}

    try:
        fh = open('/etc/login.defs')
    except IOError:
        return rv


    relevant_properties = set(['uid_min', 'sys_uid_min', 'sys_uid_max'])
    with fh:
        for line in fh:
            comment_prefix = '#'
            if line.startswith(comment_prefix):
                continue

            items = line.split()
            if len(items) != 2:
                # Invalid entry
                continue

            key, value = items
            if key.lower() in relevant_properties:
                rv[key.lower()] = int(value)

    return rv


if __name__ == '__main__':
    import pprint
    pprint.pprint(run())
