include:
    - apt-transport-https


do-agent-key:
    file.managed:
        - name: /usr/share/keyrings/digitalocean-agent-keyring.gpg
        - source: salt://do-agent/release-key.gpg


do-agent:
    file.managed:
        - name: /etc/apt/sources.list.d/digitalocean-agent.list
        - contents: |
            # File managed by salt state do-agent #
            deb [signed-by=/usr/share/keyrings/digitalocean-agent-keyring.gpg] https://repos.insights.digitalocean.com/apt/do-agent main main
        - require:
            - file: do-agent-key

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/digitalocean-agent.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: do-agent
            - file: do-agent-key

    pkg.installed:
        - require:
            - cmd: do-agent


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
        - uid-owner: do-agent
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
        - uid-owner: do-agent
        - jump: ACCEPT


{% for protocol in ('udp', 'tcp') %}
do-agent-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - destination: system_dns
        - proto: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "do-agent: Allow DNS"
        - uid-owner: do-agent
        - jump: ACCEPT
{% endfor %}
{% endfor %}
