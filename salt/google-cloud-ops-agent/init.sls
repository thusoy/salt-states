google-cloud-ops-agent-repo-key:
    file.managed:
        - name: /usr/share/keyrings/cloud.google.ops-agent.gpg
        - source: salt://google-cloud-ops-agent/apt-key.gpg


# Not adding specific pins to this repo since it's also used for other packages
# installed by default
google-cloud-ops-agent-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/google-cloud-ops-agent.list
        - contents: deb [signed-by=/usr/share/keyrings/cloud.google.ops-agent.gpg] https://packages.cloud.google.com/apt google-cloud-ops-agent-{{ grains.oscodename }}-all main
        - require:
            - file: google-cloud-ops-agent-repo-key

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/google-cloud-ops-agent.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: google-cloud-ops-agent-repo
            - file: google-cloud-ops-agent-repo-key


google-cloud-ops-agent:
    pkg.installed:
        - require:
            - cmd: google-cloud-ops-agent-repo

    service.running:
        - watch:
            - pkg: google-cloud-ops-agent
            - file: google-cloud-ops-agent

    file.managed:
        - name: /etc/google-cloud-ops-agent/config.yaml
        - template: jinja
        - source: salt://google-cloud-ops-agent/config.yaml
