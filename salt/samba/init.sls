include:
    - users


samba:
    pkg.installed:
        - name: samba

    file.managed:
        - name: /etc/samba/smb.conf
        - source: salt://samba/smb.conf
        - template: jinja
        - context:
            global:
                security: user
                disable netbios: "yes"
                smb ports: 445
                load printers: "no"
                unix extensions: "no"
                printing: bsd
                printcap name: /dev/null
            {% set sections = salt['pillar.get']('samba:sections', {}) %}
            {% if sections %}
            sections:
                {% for section_name, config in sections.items() %}
                {{ section_name }}:
                    {% for key, val in config.items() %}
                    {{ key }}: {{ val }}
                    {% endfor %}
                {% endfor %}
            {% endif %}

        - require:
            - pkg: samba

    service.running:
        - name: smbd
        - require:
            - pkg: samba
        - watch:
            - file: samba


{% for username, data in pillar.get('users', {}).items() %}

{% set samba_config = data.get('samba', {}) %}
{% if samba_config %}

{% set smbpw = samba_config.get('password') %}
samba-{{ username }}:
    cmd.run:
        - name: 'printf "$password\n$password\n" | smbpasswd -s -a {{ username }}'
        - env:
            password: {{ smbpw }}
        - output_loglevel: quiet
{% endif %}
{% endfor %}


{% for family in ('ipv4', 'ipv6') %}
samba-firewall-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - match: comment
        - comment: "samba: Allow incoming cifs connections"
        - proto: tcp
        - dport: 445
        - jump: ACCEPT
{% endfor %}
