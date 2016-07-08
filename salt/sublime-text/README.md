Sublime Text
============

Installs Sublime with Package Control and license.

Put your license key in pillar in a dict at `sublime-text:license`, where it points from the username of the user that owns that license to the key.


Sample pillar
-------------

```
sublime-text:
    users:
        tarjei:
            package_control: True
            license: |
                ----- BEGIN LICENSE -----
                Tarjei Husøy
                Single User License
                <..>
                ------ END LICENSE ------

```

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
