jenkins-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https
            - openjdk-8-jre
            - openjdk-8-jdk

jenkins:
    pkgrepo.managed:
        - name: deb https://pkg.jenkins.io/debian binary/
        - key_url: salt://jenkins/repo-key.key
        - require:
            - pkg: jenkins-deps

    pkg.installed:
        - require:
            - pkgrepo: jenkins

    file.managed:
        - name: /etc/default/jenkins
        - source: salt://jenkins/jenkins-config
        - template: jinja

    service.running:
        - require:
            - pkg: jenkins
        - watch:
            - file: jenkins
