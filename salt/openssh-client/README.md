openssh-client
==============

Installs and configures openssh-client with secure defaults, and enables provisoining system-wide known hosts.

Hosts that require an exception from the defaults can be configured in the user's ssh config.

Available configuration keys (on the 'openssh_client' pillar):
- `kex_algorithms`: Which key exchange algorithms to allow
- `ciphers`: Which ciphers to allow
- `macs`: Which MACs to allow
- `host_key_algorithms`: Which host key algorithms to prefer
- `known_hosts`: A dict mapping hostnames to a list of known keys.

See the `map.jinja` file for defaults.

Pillar example:

```yaml
openssh_client:
    known_hosts:
        "example.com":
            - ssh-rsa AAAAB3Nz<..>UoxVdTB
        "[customport.example.com]:3271":
            - ssh-ed25519 AAAAC<..>8WM1
            - ssh-rsa AAAAB3Nz<..>eLeW3TZ
```
