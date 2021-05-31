# Jump host

Assuming this is run in conjunction with the `openssh-server` state, opens the outbound firewall to arbitrary hosts.

Example pillar configuration:

```yaml
jump-host:
    allow:
        mysql:
          destination: 10.0.0.0/8
          dport: 3306

        elasticsearch:
          destination: 10.1.1.2
          dport: 9200
```
