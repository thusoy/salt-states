#!py

def run():
    """Sanity-checks the elasticsearch pillar values."""
    elasticsearch = __pillar__.get('elasticsearch', {})

    required_keys = [
        'cluster_name',
        'seed_hosts',
        'memory'
    ]
    for key in required_keys:
        assert key in elasticsearch, 'The elasticsearch pillar is missing required key "%s"' % key

    return {}
