google-cloud-repo-key:
    file.managed:
        - name: /usr/share/keyrings/cloud.google.gpg
        - source: salt://google-cloud-cli/apt-key.gpg


google-cloud-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/google-cloud.list
        # Restrict repo key to only be usable with the google cloud repo
        - contents: deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk-{{ grains.oscodename }} main
        - require:
            - file: google-cloud-repo-key

# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
google-cloud-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/google-cloud.pref
        - contents: |
            Package: *
            Pin: origin packages.cloud.google.com
            Pin-Priority: 1

            Package: google-cloud-cli
            Pin: origin packages.cloud.google.com
            Pin-Priority: 500

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/google-cloud.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: google-cloud-repo
            - file: google-cloud-repo-key
            - file: google-cloud-repo-preferences


google-cloud-cli:
    pkg.installed:
        - require:
            - cmd: google-cloud-repo-preferences
