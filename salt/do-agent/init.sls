do-agent-deps:
    pkg.installed:
        - name: apt-transport-https

do-agent:
    pkgrepo.managed:
        - name: deb https://repos.sonar.digitalocean.com/apt main main
        - key_url: salt://do-agent/release-key.asc
        - require:
            - pkg: do-agent-deps

    pkg.installed:
        - require:
            - pkgrepo: do-agent


do-agent-firewall-metadata:
    firewall.append:
        - family: ipv4
        - chain: OUTPUT
        - protocol: tcp
        - destination: 169.254.169.254
        - dport: 80
        - match:
            - comment
            - owner
        - comment: 'do-agent: Allow connecting to metadata service'
        - uid-owner: nobody
        - jump: ACCEPT


{% for family in ('ipv4', 'ipv6') %}
do-agent-firewall-collector-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'do-agent: Allow connecting to collector'
        - uid-owner: nobody
        - jump: ACCEPT
{% endfor %}
