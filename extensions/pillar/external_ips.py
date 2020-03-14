'''
Helper to provide external ip for providers that don't expose this directly to
the minion, like GCE and AWS. This is similar to minion_ips, but exposes the IP
to the minion owning it.
'''

try:
    import ipaddress
    HAS_IPADDRESS = True
except ImportError:
    HAS_IPADDRESS = False


def ext_pillar(minion_id, pillar, minion_ips_path='/etc/salt/minion_ips', **kwargs):
    try:
        fh = open(minion_ips_path)
    except:
        return {}

    with fh:
        for line in fh:
            found_minion_id, minion_ip = line.strip().split(None, 1)
            if found_minion_id == minion_id:
                all_ips = minion_ip.split()
                external_ips = []
                if HAS_IPADDRESS:
                    for ip in all_ips:
                        parsed_ip = ipaddress.ip_address(ip)
                        if parsed_ip.is_global:
                            external_ips.append(ip)
                else:
                    external_ips.extend(all_ips)
                return {
                    'external_ips': external_ips,
                }

    return {}
