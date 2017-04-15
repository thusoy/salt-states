Custom states
=============


firewall
--------

An easier interface to iptables. Provides only two functions, `append` and `apply`. Ordering of rules should be done using salt's requisite system. All rules are persistent by default (ie survives reboots).

`append` will not do anything unless `apply` is called in the same run. `append` has the same interface as `iptables.append`, but with some convenience helpers:
    - `destination`: If set to `system_dns`, the actual system DNS servers will be resolved and used in the rule. If not resolvable the rule will allow all destinations.

        If set to a IPv4 address, and the family is set to ipv6, it'll be ignored instead of throwing an error.

        If set to a IPv6 address, and the family is set to ipv4, it'll be ignored instead of throwing an error.

        If set to something that's not an IP address, the rule will allow all destinations for both families. This makes it easier to work with destinations that might be either hostname or IP, since hostnames will have to resolved with DNS (requires a separate rule) and can't be limited in the same way.


`apply` will load all the rules added in the current run, and clear others. This ensures that only rules managed by salt will persist in the ruleset, and that there are no awkward workarounds since rules will be applied gradually in the middle of the salt run.


init_script
-----------

Wrapper around `file.managed` that picks the target path based on the running init system, and will pick a file source based on that too.

Example:
```yaml
mystate:
    init_script.managed:
        - systemd: salt://mystate/systemd-job
        - upstart: salt://mystate/upstart-job
```

You can set other properties of `file.managed` like permissions and owner like you normally would.
