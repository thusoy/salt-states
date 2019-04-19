{% set spotify = pillar.get('spotify', {}) %}
{% set spotify_user = spotify.get('user') %}


spotify:
    pkgrepo.managed:
        - name: deb http://repository.spotify.com stable non-free
        - humanname: Spotify desktop client repo
        - keyid: 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90
        - keyserver: hkp://keyserver.ubuntu.com:80

    pkg.installed:
        - name: spotify-client
        - require:
            - pkgrepo: spotify


{% for family in ('ipv4', 'ipv6') %}
spotify-connect-firewall-incoming-mdns-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: udp
        - dports: 1900,5353
        - match:
            - comment
        - comment: 'spotify: connect mdns'
        - jump: ACCEPT


spotify-connect-firewall-outgoing-mdns-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: udp
        - dports: 1900,5353
        - match:
            - comment
            - owner
        - comment: 'spotify: connect mdns'

        # Be as specific as possible
        {% if spotify_user %}
        - uid-owner: {{ spotify_user }}
        {% endif %}

        - jump: ACCEPT

{% for proto in ('tcp', 'udp') %}
spotify-connect-firewall-incoming-{{ family }}-{{ proto }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: {{ proto }}
        - dport: 57621
        - sport: 57621
        - match:
            - comment
        - comment: 'spotify: connect'
        - jump: ACCEPT


spotify-connect-firewall-outgoing-{{ family }}-{{ proto }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ proto }}
        - dport: 57621
        - sport: 57621
        - match:
            - comment
            - owner
        - comment: 'spotify: connect'

        # If we know the user we can be more specific in the firewall
        {% if spotify_user %}
        - uid-owner: {{ spotify_user }}
        {% endif %}

        - jump: ACCEPT
{% endfor %}
{% endfor %}
