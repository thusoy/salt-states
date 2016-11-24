#!/usr/bin/env python

'''
Prints kernel modules that depend on the module given, ending with the module itself.
Prints nothing if the module isn't loaded
'''

from __future__ import print_function

import argparse
import subprocess


def main():
    args = get_args()
    for module in get_module_dependencies(args.module):
        print(module)


def get_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('module')
    return parser.parse_args()


def get_module_dependencies(target_module, module_tree=None):
    if module_tree is None:
        module_tree = get_current_modules()

    dependents = module_tree.get(target_module)

    if dependents is None:
        return []

    all_modules = []
    for dep in dependents:
        all_modules.extend(unique(get_module_dependencies(dep, module_tree)))
    all_modules.append(target_module)
    return unique(all_modules)


def get_current_modules():
    lsmod = ['lsmod']
    modules = {}
    for line in subprocess.check_output(lsmod).split('\n')[1:]:
        if not line:
            continue
        line_parts = line.split()
        module = line_parts[0]
        dependents = line_parts[3].split(',') if len(line_parts) == 4 else []
        modules[module] = dependents
    return modules


def unique(iterable):
    "Yields unique elements from iterable, preserving order."
    seen = set()
    # Shortcut this lookup to save python some work
    seen_add = seen.add
    for element in iterable:
        if element in seen:
            continue
        seen_add(element)
        yield element


if __name__ == '__main__':
    main()
