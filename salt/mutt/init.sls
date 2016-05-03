{% set mutt = pillar.get('mutt', {}) %}

mutt:
    pkg.installed: []

    file.managed:
        - name: /etc/Muttrc
        - source: salt://mutt/mutt.rc


mutt-source-local-dotmutt:
    file.managed:
        - name: /usr/lib/mutt/source-local-dotmutt
        - source: salt://mutt/source-local-dotmutt.sh
        - user: root
        - group: root
        - mode: 755
        - require:
            - pkg: mutt


mutt-auto-add-aliases:
    file.managed:
        - name: /usr/lib/mutt/add-alias
        - source: salt://mutt/add-alias.sh
        - user: root
        - group: root
        - mode: 755
        - require:
            - pkg: mutt


{% if 'mailname' in mutt %}
mutt-mailname:
    file.managed:
        - name: /etc/mailname
        - contents: {{ mutt.mailname }}
{% endif %}
