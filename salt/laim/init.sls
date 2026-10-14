{% set apt = salt['pillar.get']('laim:apt', {}) %}
{% set repo = apt.get('repo', 'https://repo.thusoy.com/apt/debian ' ~ grains.oscodename ~ ' main') %}
{% set list_name = apt.get('name', 'thusoy-laim') %}
{% set origin = repo.split()[0].split('://')[1].split('/')[0] %}
{% set artifact_registry = repo.startswith('ar+') %}

{% if artifact_registry %}
{% set keyring = '/usr/share/keyrings/artifact-registry.gpg' %}
include:
    - apt-transport-artifact-registry
{% else %}
{% set keyring = '/usr/share/keyrings/thusoy-archive-keyring.gpg' %}
laim-repo-key:
    file.managed:
        - name: {{ keyring }}
        - source: salt://laim/release-key.gpg
{% endif %}


laim-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/{{ list_name }}.list
        # Restrict repo key to only be usable with the laim repo
        - contents: deb [signed-by={{ keyring }}] {{ repo }}
        - require:
{% if artifact_registry %}
            - pkg: apt-transport-artifact-registry
{% else %}
            - file: laim-repo-key
{% endif %}

# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
laim-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/{{ list_name }}.pref
        - contents: |
            Package: *
            Pin: origin {{ origin }}
            Pin-Priority: 1

            Package: laim
            Pin: origin {{ origin }}
            Pin-Priority: 500

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/{{ list_name }}.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: laim-repo
{% if not artifact_registry %}
            - file: laim-repo-key
{% endif %}
            - file: laim-repo-preferences


laim:
    pkg.installed:
        - require:
            - file: laim-repo

    file.managed:
        - name: /etc/laim/config.yml
        - source: salt://laim/config.yml
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - show_changes: False
        - require:
            - pkg: laim

    service.running:
        - watch:
            - file: laim
