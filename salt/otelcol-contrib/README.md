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
              # Example:
              #  cpu state system.cpu.time
              # cpu1  idle     17709059.39
              cpu:
              # Example:
              # device direction system.disk.io system.disk.merged syste.disk.operation_time system.disk.operations
              #   sda1      read    12855464960               8253                   539.194                 480038
              disk:
              # Example:
              #    device type mode mountpoint state system.filesystem.inodes.usage system.filesystem.usage
              # /dev/sda1 ext4   rw          /  free                        2547279             37640073216
              # device system.disk.io_time system.disk.pending_operations system.disk.weighted_io_time
              # sda15                0.148                              0                        0.828
              filesystem:
              # Example:
              # system.cpu.load_average.15m system.cpu.load_average.1m system.cpu.load_average.5m system.processes.created
              #                        0.41                       0.23                       0.36                  1278022
              load:
              # Example:
              # state system.memory.usage
              #  used          2463539200
              memory:
              # Example:
              # protocol      state system.network.connections
              #      tcp FIN_WAIT_2                          2
              # device direction system.network.dropped system.network.errors system.network.io system.network.packets
              #   ens4   receive                      0                     0    21290159016809           112771255251
              network:
              # Example:
              #  type system.paging.faults
              # minor                    0
              #  type direction system.paging.operations
              # major  page_out                        0
              paging:
              # Example:
              # Common to all spans:
              #          process.command                                               process.command_line process.executable_name  process.executable_path   process.owner process.pid
              # /usr/bin/otelcol-contrib /usr/bin/otelcol-contrib --config=/etc/otelcol-contrib/config.yaml         otelcol-contrib /usr/bin/otelcol-contrib otelcol-contrib       13423
              # Unique fields in spans:
              # direction process.disk.io
              #     write               0
              # state process.cpu.time
              #  wait             0.09
              # process.memory.physical_usage process.memory.virtual_usage
              #                        114688                      8675328
              process:
                # Even though the scraper succeeds it spams the log with /exe read errors, mute those
                mute_process_name_error: true
              # Example:
              #  status system.processes.count
              # running                      1
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

The state also supports resolving data from other pillar keys or grains:

```yaml
otelcol-contrib:
    config:
        processors:
            attributes/salt:
                actions:
                    - key: some_pillar_value
                      action: upsert
                      value_pillar: some:pillar:key
```
