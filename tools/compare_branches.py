#!/usr/bin/env python

import argparse
import subprocess
from collections import OrderedDict


def main():
    args = get_args()
    local_commits = get_local_commits()
    other_commits = get_other_commits(args.branch, args.path)
    local_subjects = set(local_commits.values())
    for commitish, subject in other_commits.items():
        if subject not in local_subjects:
            print('%s %s' % (commitish, subject))


def get_local_commits():
    cmd = [
        'git',
        'log',
        '--format=%h %s',
        '--no-merges',
        '--max-count=2000',
    ]
    return parse_commits(subprocess.check_output(cmd))


def get_other_commits(branch, path):
    cmd = [
        'git',
        'log',
        '..%s' % branch,
        '--no-merges',
        '--format=%h %s',
        '--max-count=2000',
    ]
    if path:
        cmd.append('--')
        cmd.append(path)

    return parse_commits(subprocess.check_output(cmd))


def parse_commits(git_log_output):
    commits = OrderedDict()
    for line in git_log_output.decode('utf-8').split('\n'):
        line = line.strip()
        if not line:
            continue
        commitish, subject = line.split(' ', 1)
        commits[commitish] = subject

    return commits


def get_args():
    parser = argparse.ArgumentParser(description='Find commits on a given branch missing '
        'from the current branch')
    parser.add_argument('branch')
    parser.add_argument('path', nargs='?', help='Restrict search by path')
    return parser.parse_args()


if __name__ == '__main__':
    main()
