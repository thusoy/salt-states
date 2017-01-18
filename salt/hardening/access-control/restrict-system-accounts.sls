#!py
# Ref. NSA RHEL 2.3.1.4

import subprocess
import collections
import pwd

DEFAULT_UNUSED_SYSTEM_ACCOUNTS = set([
    'backup',
    'bin',
    'colord',
    'dnsmasq',
    'games',
    'gnats',
    'irc',
    'list',
    'lp',
    'news',
    'pulse',
    'saned',
    'sync',
    'sys',
    'usbmux',
    'uuidd',
    'www-data',
])


def run():
    states = {}
    for name, state in remove_unused_system_accounts():
        states[name] = state
    for name, state in remove_system_account_login_shells():
        states[name] = state
    return states


def remove_unused_system_accounts():
    for account in get_accounts_to_remove():
        yield 'hardening-remove-system-account-' + account, {
            'user.absent': [
                {'name': account},
            ]
        }


def get_accounts_to_remove():
    whitelisted_accounts = get_whitelisted_system_accounts()
    return DEFAULT_UNUSED_SYSTEM_ACCOUNTS - whitelisted_accounts


def remove_system_account_login_shells():
    whitelisted_system_account_shells = get_whitelisted_system_account_shells()
    nologin = '/usr/sbin/nologin'
    valid_shells = ('/usr/bin/false', '/bin/false', nologin)
    for user, shell in get_system_account_shells():
        valid_shells_for_user = list(valid_shells)

        whitelisted_user_shell = whitelisted_system_account_shells.get(user)
        if whitelisted_user_shell:
            valid_shells_for_user.append(whitelisted_user_shell)

        target_shell = shell if shell in valid_shells_for_user else nologin
        no_change_comment = "\nchanged=no"
        did_change_comment = "\nchanged=yes comment='Changed shell from {} to {}'".format(
            shell, nologin)
        cmd = ' | '.join([
            'usermod -s {} {} 2>&1'.format(target_shell, user),
            'grep "no changes" && echo "{}" || echo "{}"'.format(no_change_comment, did_change_comment),
        ])
        yield 'hardening-remove-system-account-login-shells-' + user, {
            'cmd.run': [{
                'name': cmd,
                'stateful': True,
            }]
        }


def get_whitelisted_system_accounts():
    return set(pillar_get('hardening:whitelisted_system_accounts', []))


def get_whitelisted_system_account_shells():
    return pillar_get('hardening:whitelisted_system_account_shells', {})


def pillar_get(key, default=None):
    try:
        pillar_get = __salt__['pillar.get']
        return pillar_get(key, default)
    except NameError:
        return default


def get_system_account_shells():
    boundaries = get_account_boundaries()
    accounts_to_remove = set(get_accounts_to_remove())
    for account in pwd.getpwall():
        if account in accounts_to_remove:
            # Don't manage the shell for this account if it's going to be removed
            continue
        username = account.pw_name
        shell = account.pw_shell
        if is_system_account(account.pw_uid, boundaries):
            yield username, shell


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


def is_system_account(uid, boundaries):
    # If sys_uid_min and sys_uid_max is specified, check that it's within those ranges,
    # otherwise check that 0 < uid < uid_min
    sys_uid_min = boundaries.get('sys_uid_min')
    sys_uid_max = boundaries.get('sys_uid_max')
    uid_min = boundaries.get('uid_min', 1000)
    if sys_uid_min and sys_uid_max:
        return sys_uid_min <= uid <= sys_uid_max
    return 0 < uid < uid_min


if __name__ == '__main__':
    import pprint
    pprint.pprint(run())
