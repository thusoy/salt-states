# laim-slack

Installs laim and a handler that defaults to posting messages to Slack, but
also parses changelogs from apt-listchanges and posts those to hHoneycomb.


## Configuration

Configure through pillar:

```yaml
laim:
    config:
        slack-channel-id: '#servers'
        slack-token: my-slack-api-token
```
