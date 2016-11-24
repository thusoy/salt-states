# Require two-factor authentication when using password-auth

include:
    - ssh
    - users

ssh-deps:
    pkg.installed:
        - name: libpam-google-authenticator
        - require_in:
            - file: ssh


ssh-pam-config:
    file.managed:
        - name: /etc/pam.d/sshd
        - source: salt://ssh/ssh-pam
        - watch_in:
            - service: ssh


{% for user, values in pillar.get('users', {}).items() %}
{% if 'google-authenticator-config' in values %}
google-authenticator-config-{{ user }}:
    file.managed:
        - name: ~{{ user }}/.google_authenticator
        - contents_pillar: users:{{ user }}:google-authenticator-config
        - user: {{ user }}
        - group: {{ user }}
        - mode: 600
{% endif %}
{% endfor %}
