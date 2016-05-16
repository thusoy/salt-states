pip
===

Installs a recent pip without using the system package manager, since these are often out of date and does not contain recent security fixes to pip. Also doesn't use the system package manager to bootstrap pip, since that often brings the system to a inconsistent state when both pip and the system package manager tries to manage pip.

To pin to a specific version, add a `pip` pillar value like this:

```yaml
pip:
    version: == 8.1.1
```

You can also use greater than or less than operators, like `>= 7, < 8`. If absent the latest version will be installed.
