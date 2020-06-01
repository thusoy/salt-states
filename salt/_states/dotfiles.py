import os
import tempfile
import subprocess
import shutil
import urllib.parse

import salt.utils.path


DOTFILES_GIT_DIR = '.dotfiles'


def __virtual__():
    if salt.utils.path.which('git'):
        return True
    return False, 'Missing a git binary'


def repo(name, repo, user):
    ret = {
        'name': name,
        'comment': '',
        'result': True,
        'changes': {},
    }
    repo_url, branch = urllib.parse.urldefrag(repo)
    branch = branch or 'master'
    home_dir = os.path.expanduser('~%s' % user)
    git_dir = os.path.expanduser('~%s/%s' % (user, DOTFILES_GIT_DIR))
    try:
        if not os.path.exists(git_dir):
            _clone_new_repo(home_dir, git_dir, repo_url, branch)
            ret['comment'] = 'Cloned branch %s from repo %s\n' % (branch, repo_url)

        changes = _pull_repo(home_dir, git_dir, branch)
    except subprocess.CalledProcessError as error:
        ret['result'] = False
        ret['comment'] += 'stderr: %s\n' % error.stderr.decode('utf-8')
        return ret

    if changes:
        ret['comment'] += 'The following dotfiles were updated'
        ret['changes']['changes'] = changes

    return ret


def _pull_repo(home_dir, git_dir, branch):
    subprocess.check_call([
        'git',
        '--git-dir', git_dir,
        'fetch',
        '--all',
        '--quiet',
    ], cwd=home_dir)
    # To ensure the diff includes changes to files that are not on master but on the
    # branch we are checking out we need to switch to that branch before running the diff,
    # but without using checkout since that'll fail if there's conflicts.
    subprocess.check_call([
        'git',
        '--git-dir', git_dir,
        'symbolic-ref',
        'HEAD',
        'refs/remotes/origin/%s' % branch,
    ], cwd=home_dir)
    subprocess.check_call([
        'git',
        '--git-dir', git_dir,
        'reset',
    ], cwd=home_dir)
    changes = subprocess.check_output([
        'git',
        '--git-dir', git_dir,
        'diff',
        '-R',
        'origin/%s' % branch,
    ], cwd=home_dir)
    subprocess.check_call([
        'git',
        '--git-dir', git_dir,
        'reset',
        '--hard',
        '--quiet',
        'origin/%s' % branch,
    ], cwd=home_dir)

    return changes


def _clone_new_repo(home_dir, git_dir, repo, branch):
    with tempfile.TemporaryDirectory(dir=home_dir) as tempdir:
        subprocess.check_call([
            'git',
            'clone', repo,
            tempdir,
            '--quiet',
        ])
        os.rename(os.path.join(tempdir, '.git'), git_dir)
        subprocess.check_call([
            'git',
            '--git-dir', git_dir,
            'config',
            'status.showUntrackedFiles', 'no',
        ], cwd=home_dir)
