google-cloud-ops-agent
=========================

Installs and configures google-cloud-ops-agent.

Pillar example:

```yaml
google-cloud-ops-agent:
    config:
        # Disable metrics collection
        # Ref. https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/configuration#metrics-service-examples
        metrics:
          service:
            pipelines:
              default_pipeline:
                receivers: []

```
