{% set terraform = pillar.get('terraform', {}) %}

terraform-repo-key:
    file.managed:
        - name: /usr/share/keyrings/hashicorp-archive-keyring.gpg
        - source: salt://terraform/release-key.gpg


terraform-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/hashicorp-terraform.list
        # Restrict repo key to only be usable with the hashicorp repo
        - contents: deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com {{ grains.oscodename }} main
        - require:
            - file: terraform-repo-key


# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
terraform-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/hashicorp-terraform.pref
        - contents: |
            Package: *
            Pin: origin apt.releases.hashicorp.com
            Pin-Priority: 1

            Package: terraform
            Pin: origin apt.releases.hashicorp.com
            Pin-Priority: 500

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/hashicorp-terraform.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: terraform-repo
            - file: terraform-repo-key
            - file: terraform-repo-preferences


terraform:
    pkg.installed:
        {% if 'version' in terraform %}
        - version: {{ terraform.version }}
        {% endif %}
        - require:
            - cmd: terraform-repo-preferences
