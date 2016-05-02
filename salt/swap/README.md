swap
====

Adds a swap file and ensures swap is turned on. Customize through the swap pillar if you want bigger than the default 1GB:

    swap:
        size_mb: 4096

Default location is `/.swapfile`, but can be customized by setting the property `location` on the swap pillar.
