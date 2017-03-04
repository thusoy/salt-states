iptables
========

Makes the inbound firewall rejecting, and enables setting the outbound rejecting too, and adds some default sane rules for the firewall.

Namely, all incoming traffic will be subjected to a sanity check that the packets are valid and doesn't originate from invalid addresses (see the `.sanity-check.sls` state for details), and all established traffic will be allowed. Incoming and outgoing ICMP and ICMPv6 will be filtered to a sane subset (see `.icmp.sls` state for details). You can also blacklist known bad IPs that will be rejected early.

Customizations available through the `iptables` pillar:
- `output_policy`: Which policy to apply to the OUTPUT chain
- `blocklist`: IPs or ranges to block (IPv4 only)

See `iptables/map.jinja` for defaults.

Rejected traffic (in or out) will be logged (with rate-limiting), and logrotate configured to prune old logs.
