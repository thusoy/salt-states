# salt-states [![Build Status](https://travis-ci.org/thusoy/salt-states.svg?branch=master)](https://travis-ci.org/thusoy/salt-states)

Because sharing is caring.

Only written for Debian/Ubuntu for now, send a PR or file an issue if you'd
like support for a state on a different platform.

Uses `show_changes` instead of the deprecated `show_diff`, so ensure you're using at least salt version `2016.3` to avoid secret discloure in logs and output.

Add the following to your master/minion config to get going:

```yaml
fileserver_backend:
    - roots
    - git

gitfs_remotes:
    - https://github.com/thusoy/salt-states

gitfs_env_whitelist:
    - base

gitfs_root: salt
```

If you want to use the salt extensions defined in this repo you have to clone
it to your saltmaster instead of using gitfs. Add a regular cron job to keep the
repo up to date, then add the following to your master config (assuming you
cloned the repo to `/srv/salt/salt-states`):

```yaml
file_roots:
    base:
        - ..
        - /srv/salt/salt-states/salt

# Set where to find extensions
module_dirs:
    - /srv/salt/salt-states/extensions
```


## Development

To create new states:

* Install vagrant and virtualbox.
* `$ vagrant up`
* `$ vagrant ssh`

You're now logged onto a VM that has salt installed in masterless mode. To
apply a state:

`$ sudo salt-call state.sls <mystate>`

When adding a new state, include a README.md with a brief description and an
overview of the options that can be configured through pillar. Look at some of
the existing states for inspiration.

Pillar values are defined in `pillar/test.sls`, only commit your changes to this
if you want to preserve it as a reference for how to use the module or some
changes are required and you want to make it easy to apply the module when
working on it. None of the values defined in this pillar will apply to a
production deployment using this repo.

There's a small helper to bootstrap new states that are wrappers around debian
packages in `./tools/add-package-state.sh`, can be used for simple stuff.


## Guidelines

1) **Always add a marker to managed files**. In the marker you should specify
   which state is managing it. When debugging this makes it easier to determine
   if something is a default config file or something explictly put in place:
   ```
   #############################################
   # File managed by salt state openssh_server #
   #############################################
   ```

2) **Explicitly open up firewalls**. Assume the state is going to be applied to
   a host with locked down inbound and outbound firewall. Any networking your
   state is going to do needs to be explicitly allowed through the firewall,
   with a comment saying which state added the rule:
    ```
    - dport: 443
    - match:
        - comment
    - comment: 'nginx: Allow inbound https'
    ```

3) **Explicitly validate pillar data**. This ensures invalid configuration is
   caught as early as possible with clear error messages as to what is missing.
   In the state:
   ```yaml
   include:
       - .pillar_check
   ```
   In `<state>/pillar_check.sls`
   ```py
   #!py

   def run()
       nginx = __pillar__.get('nginx', {})
       assert 'tls_cert' in nginx, 'The nginx pillar must defined a key nginx:tls_cert'
       return {}
   ```

4) **Never write sensitive data to the salt output**. In other words, every file
   that contains secrets should include `- show_changes: False`. If possible
   through includes or similar, put the secrets in it's own file so that one
   still gets a useful diff for the rest of the file.

5) **Don't put values into the statement name**. The names are identifiers and
   should look as such. Ie, do this:
   ```yaml
   mystate-file:
       file.managed:
           - name: /etc/mystate/config.yml
           - contents: 'foobar'
   ```
   Don't do this:
   ```yaml
   # BAD EXAMPLE - DON'T DO THIS
   /etc/mystate/config.yml:
       file.managed:
           - contents: 'foobar'
   ```
   This makes them easier to modify from pillar and reference from other states
   and statements.

6) **Secure by default**. Where a service doesn't already apply hardening
   measures by default, try to remedy that from the state.

7) **Specify pillar defaults in `map.jinja`**. This makes it easier to find
   default values and import the values from several locations, ie the state
   and the its config file.

8) **Avoid over-complicated jinja states**. If you can't easily express the
   state as jinja+yaml, just use python. This also makes it easy for you to add
   simple unit tests verifing that it outputs what you want.

9) **Keep it simple**. You don't need to enable customizing every possible
   property from the start. When you find it's necessary, then enable
   customizing it from pillar (or change the default).
