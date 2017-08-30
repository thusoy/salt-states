#!py

def run():
    """ Sanity-checks the rsyslog.papertrail pillar values."""
    papertrail_rule = __salt__['pillar.get']('rsyslog:papertrail')
    assert papertrail_rule is not None

    # Ensure the rule contains @@ to deliver over TLS
    assert papertrail_rule.split(' ', 1)[1].startswith('@@'), ('Missing @@ to '
        'deliver to papertrail over TLS')

    return {}
