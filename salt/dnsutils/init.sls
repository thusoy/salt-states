# dnsutils is only a virtual package from trixie on, which pkg.installed
# reports as failed even after installing the provider. bind9-dnsutils is
# the real package since bullseye.
dnsutils:
    pkg.installed:
        - name: {{ 'bind9-dnsutils' if grains['osmajorrelease']|int >= 11 else 'dnsutils' }}
