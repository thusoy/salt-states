'''
Helper to provide external ip for providers that don't expose this directly to
the minion, like GCE and AWS. This is similar to minion_ips, but exposes the IP
to the minion owning it.
'''

def ext_pillar(minion_id, pillar, minion_ip_path='/etc/salt/minion_ips', **kwargs):
    try:
        fh = open(minion_ip_path)
    except:
        return {}

    with fh:
        for line in fh:
            found_minion_id, minion_ip = line.strip().split(None, 1)
            if found_minion_id == minion_id:
                return {
                    'external_ips': minion_ip.split(),
                }

    return {}
