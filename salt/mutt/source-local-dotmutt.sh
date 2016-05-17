#!/bin/sh -e

# Source all the config files in ~/.mutt
config_dir=~/.mutt
test -d "$config_dir" && find "$config_dir" \
    -type f \
    -name "*.rc" \
    -readable \
    -exec echo source \"{}\" \;
