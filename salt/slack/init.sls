{% set slack = pillar.get('slack', {}) %}
{% set version = slack.get('version', '2.1.0') %}

slack:
    pkg.installed:
        - sources:
            - slack-desktop: https://downloads.slack-edge.com/linux_releases/slack-desktop-{{ version }}-amd64.deb
