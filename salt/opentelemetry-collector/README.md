# opentelemetry-collector

Installs the opentelemetry collector.

Configuration:

```yaml
opentelemetry-collector:
    exporter_ports: 443,1777 # Which outbound ports to open in the firewall
    config:
        .. # dumped straight into /etc/otel-collector/config.yaml

```
