{% set sasl2 = pillar.get('sasl2', {}) %}
{% set service = sasl2.get('service') %}
{% set service_user = sasl2.get('service_user') %}

include:
    - .pillar_check


sasl2:
    pkg.installed:
        - name: sasl2-bin

    file.managed:
        - name: /etc/sasl2/{{ service }}.conf
        - source: salt://sasl2/sasl2.conf
        - template: jinja
        - context:
            db_path: '/etc/sasl2/{{ service }}-sasldb2'
        - require:
            - pkg: sasl2

    cmd.run:
        - name: rm /etc/sasl2/{{ service }}-sasldb2
                && saslpasswd2 -p -a {{ service }} -c -f /etc/sasl2/{{ service }}-sasldb2 {{ sasl2.get('username') }}
                && chown {{ service_user }}:{{ service_user }} /etc/sasl2/{{ service }}-sasldb2
        - stdin: '{{ sasl2.get('password') }}'
        - require:
            - pkg: sasl2
