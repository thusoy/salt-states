{% set sentry_forwarder = pillar.get('sentry_forwarder', {}) %}

sentry-forwarder-deps:
    pkg.installed:
        - pkgs:
            - python-virtualenv
            - python3


sentry-forwarder:
    file.managed:
        - name: /srv/sentry-forwarder/sentry_forwarder.py
        - source: salt://sentry-forwarder/sentry_forwarder.py
        - makedirs: True

    init_script.managed:
        - systemd: salt://sentry-forwarder/job-systemd
        - template: jinja
        - context:
            sampling_rate: {{ sentry_forwarder.get('sampling_rate', 1) }}
            port: {{ sentry_forwarder.get('port', 5000) }}


    virtualenv.managed:
        - name: /srv/sentry-forwarder/venv
        - python: python3
        - requirements: salt://sentry-forwarder/requirements.txt
        - require:
            - file: sentry-forwarder

    user.present:
        - name: sentry-forwarder
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin

    service.running:
        - require:
            - user: sentry-forwarder
        - watch:
            - file: sentry-forwarder
            - init_script: sentry-forwarder
            - virtualenv: sentry-forwarder

{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
sentry-forwarder-firewall-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'sentry-forwarder: Allow outgoing dns'
        - uid-owner: sentry-forwarder
        - jump: ACCEPT
        - require:
            - user: sentry-forwarder
{% endfor %}


sentry-forwarder-firewall-outgoing-https-{{ family }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'sentry-forwarder: Allow outgoing https'
        - uid-owner: sentry_forwarder
        - jump: ACCEPT
        - require:
            - user: sentry-forwarder
{% endfor %}
