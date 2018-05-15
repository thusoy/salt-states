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
