# otelcol-contrib

Installs the opentelemetric collector contrib service. This state also enables you to override the capabilities of the service to grant it access to read the data of other processes, which is needed for `receivers:hostmetrics:process` to not error when trying to read the `/proc/[pid/exe` (which probably could be avoided by reading the cmdline instead, but not sure).

To configure it to send host metrics to honeycomb:
```yaml
otelcol-contrib:
    # Required for the `process` scraper to be able to read other processes
    extra_capabilities: [CAP_SYS_PTRACE]
    config:
        receivers:
          hostmetrics:
            collection_interval: 10s
            scrapers:
              cpu:
              disk:
              filesystem:
              load:
              memory:
              network:
              paging:
              process:
                # You likely want this to avoid the logspam from /exe read errors, even
                # though the scraper succeeds as long as the CAP_SYS_PTRACE capability
                # is granted
                mute_process_name_error: true
              processes:

        processors:
          resourcedetection/system:
            detectors: ["system"]
            system:
              hostname_sources: ["os"]

        exporters:
          otlp:
            endpoint: "api.honeycomb.io:443"
            headers:
              "x-honeycomb-team": "YOUR_WRITEKEY"
              "x-honeycomb-dataset": "YOUR_DATASET"

        service:
          pipelines:
            metrics:
              receivers: [hostmetrics]
              processors: [resourcedetection/systems]
              exporters: [otlp]
```
