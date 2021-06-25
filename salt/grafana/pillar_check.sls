#!py

def run():
    """ Sanity-checks the grafana pillar values."""
    grafana = __pillar__.get('grafana', {})

    assert 'domain' in grafana, 'Must define grafana:domain'

    return {}
