# salt-states

Because sharing is caring.

Only written for Debian/Ubuntu for now, send a PR or file an issue if you'd
like support for a state on a different platform.

Add the following to your master/minion config to get going:

```yaml
fileserver_backend:
	- roots
	- git

gitfs_remotes:
	- https://github.com/thusoy/salt-states	
```
