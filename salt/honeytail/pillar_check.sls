#!py

def run():
    """Sanity-checks the honeytail pillar values."""
    honeytail = __pillar__.get('honeytail', {})

    required_keys = [
        'write_key',
        'dataset',
        'log_file',
        'parser_name',
    ]
    for key in required_keys:
        assert key in honeytail, 'The honeytail pillar is missing required key "%s"' % key

    return {}
