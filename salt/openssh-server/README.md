openssh-server
==============

Installs and configures openssh-server.

By default only allows users in the 'ssh' group access, you can disable this by setting `allow_groups: []`. You can also whitelist specific users by setting `allow_users`.

Denies root logins and only allows pubkey auth. Might enable allowing passwords if combined with 2FA/U2F in the future if desired.

Available configuration through the pillar `openssh_server`:
- `port`: Which port to listen to
- `host_ed25519_key | host_rsa_key | host_ecdsa_key`: Set the server key to these keys.
- `kex_algorithms`: Which key exchange algorithms to allow
- `ciphers`: Which ciphers to allow
- `macs`: Which MACs to allow
- `allow_groups`: Groups allowed to log in
- `allow_users`: Users allowed to log in
- `minimum_modulus_size`: The smallest allowed modulus used for the DH handshake
- `listen_addresses`: Which addresses to bind to.
- `allow_from:ipv4`: IPv4 addresses to allow access. Default is open to all.
- `allow_from:ipv6`: IPv6 addresses to allow access. Default is open to all.

See the `map.jinja` file for defaults.
