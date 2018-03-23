{% set jenkins = pillar.get('jenkins', {}) %}

include:
    - .agent_pillar_check

jenkins-ssh-group:
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
            - group: jenkins-ssh-group

    ssh_auth.present:
        - user: jenkins
        - names:
            - {{ jenkins.get('master_ssh_pubkey') }}
        - require:
            - user: jenkins-agent-user
