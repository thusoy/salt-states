Sublime Text
============

Installs Sublime Text 3. To install a dev version instead of stable, set the following in pillar:

```yaml
sublime-text:
    channel: dev
```

Your license key should be installed outside of this state by putting the key in `~/.config/sublime-text-3/Local/License.sublime_license`.

Your packages will be installed automatically if you put them in the file `~/.config/sublime-text-3/Packages/User/Package Control.sublime-settings`, which has the following format:

```
{
        "bootstrapped": true,
        "installed_packages":
        [
                "EditorConfig",
                "Package Control",
                "Pretty JSON",
                "Solarized Color Scheme"
        ]
}
```
