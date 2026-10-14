# apt-transport-artifact-registry

Installs Google's apt transport for Artifact Registry, so apt can install from
private `ar+https://` sources. apt runs it as the `_apt` user, and it
authenticates with application default credentials: on GCE, a token for the
VM's service account from the metadata server. The VM's service account needs
`roles/artifactregistry.reader` on the repository.

`/usr/share/keyrings/artifact-registry.gpg` holds the key that signs Artifact
Registry apt repos, from https://us-east4-apt.pkg.dev/doc/repo-signing-key.gpg
(fingerprint 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3).
