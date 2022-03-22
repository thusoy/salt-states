sudo:
    pkg.installed: []

    # JSON logging is only available with sudo 1.9, which is included
    # from debian bullseye and upwards
    {% if grains['osmajorrelease']|int >= 11 %}
    file.managed:
        - name: /etc/sudoers.d/json_logging
        - contents: |
            ###################################
            # File managed by salt state sudo #
            ###################################

            Defaults log_format=json
    {% endif %}

    # Logging of subcommands is only available with sudo 1.9.8, which is included
    # from debian bookworm and upwards
    {% if grains['osmajorrelease']|int >= 12 %}
    file.managed:
        - name: /etc/sudoers.d/json_logging
        - contents: |
            ###################################
            # File managed by salt state sudo #
            ###################################

            Defaults log_subcmds
    {% endif %}
