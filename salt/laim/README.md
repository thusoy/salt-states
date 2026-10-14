Laim
====

Installs and configures laim, but does not install a handler. You should write your own state that deploys the handler and include this state.

Values under `laim:config` can reference other pillar values by suffixing the key
with `_pillar`, ie `honeycomb-key_pillar: terraform:laim_honeycomb_key` becomes
`honeycomb-key` with the value of `terraform:laim_honeycomb_key`. See
`mdl_saltdata.resolve_leaf_values` for details.

By default laim is installed from https://repo.thusoy.com. To install it from
another apt repo, set `laim:apt:repo` to the rest of the sources line after
`deb [signed-by=...]`, and `laim:apt:name` to the basename for its sources and
preferences files:

```yaml
laim:
    apt:
        name: medal-apt-trixie
        repo: ar+https://us-east4-apt.pkg.dev/projects/<project> <repository> main
```

An `ar+https://` repo is a private Artifact Registry repo: the state then
includes `apt-transport-artifact-registry` and uses its keyring, and the VM's
service account needs `roles/artifactregistry.reader` on the repo.
