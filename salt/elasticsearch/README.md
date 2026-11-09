# Elasticsearch

Installs elasticsearch with initial seed hosts.

Configuration example:

```yaml
elasticsearch:
    cluster_name: example-cluster
    memory: 1g
    seed_hosts:
        - 127.0.0.1
        - 1.2.3.4
```

Set `gcs_snapshot_egress: true` to let the elasticsearch user make outgoing HTTPS
connections, which a GCS snapshot repository needs. The GCS credentials are not
managed here: add them to the keystore by hand with
`elasticsearch-keystore add-file gcs.client.<client>.credentials_file <file>`
on every node, then call `POST _nodes/reload_secure_settings`.

The state includes a default log config, but this can be overridden like this:

```yaml
elasticsearch:
    log4j2.properties: |
        appender.rolling.type = RollingFile
        appender.rolling.name = rolling
        appender.rolling.fileName = ${sys:es.logs.base_path}/rolling-log.json
```
