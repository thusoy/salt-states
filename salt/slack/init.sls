{% set slack = pillar.get('slack', {}) %}
{% set version = slack.get('version', '3.1.1') %}

slack:
    pkg.installed:
        - sources:
            - slack-desktop: https://downloads.slack-edge.com/linux_releases/slack-desktop-{{ version }}-amd64.deb
