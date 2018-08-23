#!py

def run():
    """Sanity-checks the ghost-cli pillar values."""
    ghost_cli = __pillar__.get('ghost-cli', {})
    assert 'user_password' in ghost_cli, "ghost_cli doesn't have user_password set in pillar, which is necessary for sudo"
    return {}
