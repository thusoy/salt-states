include:
    - apt-transport-https


jenkins-deps:
    pkg.installed:
        - pkgs:
            - openjdk-11-jre
            - openjdk-11-jdk

jenkins:
    pkgrepo.managed:
        - name: deb https://pkg.jenkins.io/debian binary/
        - key_url: salt://jenkins/repo-key.key
        - require:
            - pkg: jenkins-deps

    pkg.latest:
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
