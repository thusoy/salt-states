pyenv
=====

Installs pyenv into a user's shell.

Assumes user definitions are defined in the `users` pillar, and that each entry has an entry `install` that defines an item `pyenv`. Also the user must have a line in their `.bash_rc` that sources files in `~/.bash_source`.

Example:

```
users:
    thusoy:
        install:
            - pyenv
```
