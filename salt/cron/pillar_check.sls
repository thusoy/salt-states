#!py

def run():
    cron = __pillar__.get('cron', {})

    assert 'mailto' in cron, 'cron pillar must specify a "mailto" key'

    return {}
