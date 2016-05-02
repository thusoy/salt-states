pip
===

Installs a recent pip without using the system package manager, since these are often out of date and does not contain recent security fixes to pip. Also doesn't use the system package manager to bootstrap pip, since that often brings the system to a inconsistent state when both pip and the system package manager tries to manage pip.
