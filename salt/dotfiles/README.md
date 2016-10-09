dotfiles
========

Load dotfiles from a user pillar and place in home directory of the user.

Example:

```
users:
    thusoy:
        dotfiles:
            .vimrc: dotfiles:thusoy:vimrc
```

This will put a file with the contents of the `dotfiles:thusoy:vimrc` pillar at `/home/thusoy/.vimrc`.

Or you can override the parameters sent to `file.managed`:

```
users:
    thusoy:
        dotfiles:
            .vimrc:
                source: dotfiles:thusoy:vimrc
                mode: 600
                template: jinja
```
