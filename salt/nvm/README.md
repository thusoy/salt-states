nvm
===

Installs nvm. You have to specify a user and a target directory to install to, and add it to your $PATH manually or in another state.

Pillar example:

```yaml
nvm:
    target_dir: /home/user/.local/nvm
    user: user
```

Then add `. ~/.local/nvm/nvm.sh` to `~user/.bashrc` and it should work.
