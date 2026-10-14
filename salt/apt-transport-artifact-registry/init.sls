# The same key signs Google's package repo for the transport and every
# Artifact Registry apt repo, so states using an ar+https:// source can use it
# as their keyring too.
apt-transport-artifact-registry-repo-key:
    file.managed:
        - name: /usr/share/keyrings/artifact-registry.gpg
        - source: salt://apt-transport-artifact-registry/apt-key.gpg


apt-transport-artifact-registry-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/apt-transport-artifact-registry.list
        # Restrict repo key to only be usable with this repo
        - contents: deb [signed-by=/usr/share/keyrings/artifact-registry.gpg] https://packages.cloud.google.com/apt apt-transport-artifact-registry-stable main
        - require:
            - file: apt-transport-artifact-registry-repo-key

# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
apt-transport-artifact-registry-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/apt-transport-artifact-registry.pref
        - contents: |
            Package: *
            Pin: origin packages.cloud.google.com
            Pin-Priority: 1

            Package: apt-transport-artifact-registry
            Pin: origin packages.cloud.google.com
            Pin-Priority: 500

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/apt-transport-artifact-registry.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: apt-transport-artifact-registry-repo
            - file: apt-transport-artifact-registry-repo-key
            - file: apt-transport-artifact-registry-repo-preferences


apt-transport-artifact-registry:
    pkg.installed:
        - require:
            - cmd: apt-transport-artifact-registry-repo-preferences
