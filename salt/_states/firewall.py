from collections import defaultdict
import atexit
import difflib
import jinja2
import json
import os
import socket
import subprocess

RULES_TEMPLATE = jinja2.Template('''
{% if nat_rules %}
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
{% for chain in nat_chains|default([]) -%}
:{{ chain }} - [0:0]
{% endfor %}

{% for rule in nat_rules|default([]) -%}
{{ rule }}
{% endfor -%}

COMMIT
{% endif %}


*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT {{ output_policy }} [0:0]
{% for chain in filter_chains|default([]) -%}
:{{ chain }} - [0:0]
{% endfor %}

{% for rule in filter_rules|default([]) -%}
{{ rule }}
{% endfor -%}

COMMIT
''')


def register_cleanup_of_file(file_path):
    """ Clean up rules on disk when exiting to prevent them from leaking between runs.

    Since a state run might be aborted before apply() runs we have do it even though
    it might not have been read.
    """
    @atexit.register
    def cleanup():
        try:
            os.remove(file_path)
        except:
            pass


def _add_rule(target_file, key, rule):
    # Each rule is stored as a single line in the file, as a json
    # object with table -> rule
    object_to_store = {
        key: rule,
    }

    schduled_deletions = __context__.get('firewall.scheduled_file_deletion', [])
    if not target_file in schduled_deletions:
        register_cleanup_of_file(target_file)
        schduled_deletions.append(target_file)
        __context__['firewall.scheduled_file_deletion'] = schduled_deletions

    with open(target_file, 'a') as fh:
        json.dump(object_to_store, fh)
        fh.write('\n')



def append(name, chain='INPUT', table='filter', family='ipv4', **kwargs):
    assert family in ('ipv4', 'ipv6')
    assert table in ('filter', 'nat')

    destination = kwargs.get('destination')
    # Some convenience utilities for destinations here, first we allow specifying that the
    # intended destination is the system dns servers, which will figure out which those are
    # and add the correct IPs, but allow all traffic if we can't determine their IPs
    if destination == 'system_dns':
        grain_lookup = 'dns:%s_nameservers' % family.replace('v', '')
        dns_servers = __salt__['grains.get'](grain_lookup)
        if dns_servers:
            kwargs['destination'] = ','.join(dns_servers)
        else:
            del kwargs['destination']
    elif _is_ipv4(destination) and family == 'ipv6' or _is_ipv6(destination) and family == 'ipv4':
        return {
            'name': name,
            'comment': 'Ignored due to wrong family for destination %s' % destination,
            'result': True,
            'changes': {},
        }
    elif destination and not _is_ipv6(destination) and not _is_ipv4(destination):
        # not a valid address, assume hostname and allow all destinations
        del kwargs['destination']

    partial_rule = __salt__['iptables.build_rule'](**kwargs)
    full_rule = '-A %s %s' % (chain, partial_rule)

    file_target = get_cached_rule_file_for_family(family[-2:])
    _add_rule(file_target, '%s_rules' % table, full_rule)

    return {
        'name': name,
        'comment': '',
        'result': True,
        'changes': {},
    }


def chain_present(name, table='filter', family='ipv4', **kwargs):
    assert table in ('filter', 'nat')
    assert family in ('ipv4', 'ipv6')

    file_target = get_cached_rule_file_for_family(family[-2:])
    _add_rule(file_target, '%s_chains' % table, name)

    return {
        'name': name,
        'result': True,
        'changes': {},
        'comment': '',
    }


def get_cached_rule_file_for_family(family):
    assert family in ('v4', 'v6')
    cachedir = __opts__['cachedir']
    file_target = os.path.join(cachedir, 'firewall-rules-%s.json' % family)
    return file_target


def _get_rules(path):
    try:
        fh = open(path)
    except OSError:
        return {}
    with fh:
        all_rules = defaultdict(list)
        for line in fh:
            parsed_line = json.loads(line)
            for key, value in parsed_line.items():
                all_rules[key].append(value)
        return all_rules


def apply(name, output_policy='ACCEPT', apply=True):
    '''
    Build and apply the rules.
    :param apply: Set this to False to only build the ruleset on disk.
    '''
    comment = []
    if not apply:
        comment.append('Built only, not applied')
    changes = {}
    success = True
    for family in ('v4', 'v6'):
        file_target = get_cached_rule_file_for_family(family)

        context = {
            'output_policy': output_policy,
        }
        context.update(_get_rules(file_target))

        result, stderr, rule_changes = _apply_rule_for_family('rules.%s' % family,
            context, 'ip%stables-restore' % ('' if family == 'v4' else '6'), apply)

        if stderr:
            comment.append(stderr)

        if rule_changes:
            changes['ip%s' % family] = rule_changes

        if result != 0:
            success = False

        # Clear out the rules on disk (will also be done on exit if run stops before applying the rules)
        os.remove(file_target)

    return {
        'name': name,
        'comment': '\n'.join(comment),
        'result': success,
        'changes': changes,
    }


def _apply_rule_for_family(filename, context, restore_command, apply):
    rendered_rules = RULES_TEMPLATE.render(context)

    # iptables-restore fails to parse if the rules doesnt end with newline
    if not rendered_rules[-1] == '\n':
        rendered_rules += '\n'

    # Ensure that the target directory exists
    if not os.path.exists('/etc/iptables'):
        os.makedirs('/etc/iptables')

    # First, read old content so that we can compute a diff (but might not exist already)
    target_file = '/etc/iptables/%s' % filename
    try:
        with open(target_file) as fh:
            old_content = fh.readlines()
    except IOError:
        old_content = []

    with open(target_file, 'w') as fh:
        fh.write(rendered_rules)

    new_content = [line + '\n' for line in rendered_rules[:-1].split('\n')]
    changes = ''.join(difflib.unified_diff(old_content, new_content))

    if apply:
        restore_process = subprocess.Popen([restore_command],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        _, stderr = restore_process.communicate(rendered_rules.encode('utf-8'))
        result = restore_process.wait()
    else:
        result = 0
        stderr = ''
    return (result, stderr, changes)


def _is_ipv4(address):
    '''
    >>> _is_ipv4('1.1.1.1')
    True
    >>> _is_ipv4('2.2.2.2/32')
    True
    >>> _is_ipv4('2001:db8::')
    False
    '''
    return _is_ip_family(socket.AF_INET, address.split('/', 1)[0])


def _is_ipv6(address):
    '''
    >>> _is_ipv6('2001:db8::')
    True
    >>> _is_ipv6('2001:db8::/64')
    True
    >>> _is_ipv6('1.1.1.1')
    False
    '''
    return _is_ip_family(socket.AF_INET6, address.split('/', 1)[0])


def _is_ip_family(family, address):
    # Asssumes that inet_pton exists, which is fair since this state only works
    # on systems with iptables anyway
    if not address:
        return False
    try:
        socket.inet_pton(family, address)
    except socket.error:  # not a valid address
        return False
    return True
