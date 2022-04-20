vault-repo-key:
    file.managed:
        - name: /usr/share/keyrings/hashicorp-archive-keyring.gpg
        - source: salt://vault/release-key.gpg


vault-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/hashicorp.list
        # Restrict repo key to only be usable for the hashicorp repo
        - contents: deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg arch=amd64] https://apt.releases.hashicorp.com {{ grains.oscodename }} main
        - require:
            - file: vault-repo-key


# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
vault-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/hashicorp-vault.pref
        - contents: |
            Package: *
            Pin: origin apt.releases.hashicorp.com
            Pin-Priority: 1

            Package: vault
            Pin: origin apt.releases.hashicorp.com
            Pin-Priority: 500

    cmd.watch:
        - name: apt-get update -y
        - watch:
            - file: vault-repo
            - file: vault-repo-key
            - file: vault-repo-preferences
