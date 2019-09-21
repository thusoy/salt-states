Sentry forwarder
================

Runs a local service that forwards events to Sentry with a given sampling rate. Use this to control the volume you send to stay within a given quota.

Configuration:

```yaml
sentry_forwarder:
    sampling_rate: 3 # default is 1, ie no sampling
    port: 5010 # default is 5000
```

The service is only exposed to localhost, wrap in a reverse proxy that handles TLS to expose it to the world.
