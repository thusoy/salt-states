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
