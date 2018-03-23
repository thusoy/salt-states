{% set jenkins = pillar.get('jenkins', {}) %}

include:
    - .agent_pillar_check


jenkins-agent-deps:
    pkg.installed:
        - pkgs:
            - openjdk-8-jre
            - openjdk-8-jdk


jenkins-agent-ssh-group:
    group.present:
        - name: ssh


jenkins-agent-user:
    user.present:
        - name: jenkins
        - empty_password: True
        - gid_from_name: True
        - fullname: Jenkins Agent
        - groups:
            - ssh
        - require:
            - group: jenkins-agent-ssh-group

    ssh_auth.present:
        - user: jenkins
        - names:
            - {{ jenkins.get('master_ssh_pubkey') }}
        - require:
            - user: jenkins-agent-user
