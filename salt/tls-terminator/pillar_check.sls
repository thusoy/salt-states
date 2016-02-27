#!py

def run():
    """ Sanity check TLS-terminator pillar values before excecution. """
    for site, values in __pillar__.get('tls-terminator', {}).items():
        assert 'backend' in values, ('TLS-terminator site %s is '
            "missing mandatory property '%s'" % (site, required_property))

