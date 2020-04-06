{% set plex = pillar.get('plex-media-server', {}) %}
{% set allow_from = plex.get('allow_from', {}) %}
{% set allow_ipv4 = allow_from.get('ipv4', '0/0')) %}
{% set allow_ipv6 = allow_from.get('ipv6', '::/0') %}

{% set network_ports = {
    'Plex Media Server': ('tcp', 32400),
    'Plex DLNA Server': ('udp', 1900),
    'Plex Companion': ('tcp', 3005),
    'Plex TCP DLNA Server': ('tcp', 32469),
    'network discovery': ('udp', '5353,32410,32412-32414'),
    'Roku via Plex Companion': ('tcp', 8324),
} %}


include:
    - apt-transport-https


plex-media-server:
    pkgrepo.managed:
        - name: deb https://downloads.plex.tv/repo/deb public main
        - key_url: salt://plex-media-server/release-key.asc

    pkg.installed:
        - name: plexmediaserver
        - require:
            - pkgrepo: plex-media-server

    service.running:
        - name: plexmediaserver
        - watch:
            - pkg: plex-media-server


{% for family in ('ipv4', 'ipv6') %}
{% for service, (protocol, port) in network_ports.items() %}
plex-media-server-inbound-firewall-{{ family }}-{{ service.lower().replace(' ', '-') }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: {{ protocol }}
        - dports: {{ port }}
        - source: {{ allow_ipv4 if family == 'ipv4' else allow_ipv6 }}
        - match:
            - comment
            - owner
        - comment: 'plex-media-server: Allow inbound {{ service }}'
        - uid-owner: plex
        - jump: ACCEPT
        - require:
            - pkg: plex-media-server
{% endfor %}
{% endfor %}
