{% set needs_backports = grains.oscodename == 'jessie' %}

ffmpeg:
    {% if needs_backports %}
    pkgrepo.managed:
        - name: deb http://ftp.debian.org/debian jessie-backports main
    {% endif %}

    pkg.installed:
        - name: ffmpeg
        {% if needs_backports %}
        - require:
            - pkgrepo: ffmpeg
        {% endif %}
