spotifyd
========

Installs the spotifyd daemon and starts it as a systemd service. ALSA or other audio backend setup needs to be done in another state, set the backend to use in pillar:

```yaml
spotifyd:
    username: fo
    password: bar
    backend: alsa
``

All supported config is forwarded from pillar to the spotifyd config file.
