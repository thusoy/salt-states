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
    if os.path.exists(git_dir):
        try:
            changes = _pull_repo(home_dir, git_dir, branch)
        except subprocess.CalledProcessError as error:
            ret['result'] = False
            ret['comment'] = error.stderr.decode('utf-8')
            return ret

        if changes:
            ret['comment'] = 'The following dotfiles were updated'
            ret['changes']['changes'] = changes
    else:
        try:
            diff = _clone_new_repo(home_dir, git_dir, repo_url, branch)
        except subprocess.CalledProcessError as error:
            ret['result'] = False
            if error.stdout:
                ret['comment'] += 'stdout: %s\n' % error.stdout.decode('utf-8')
            if error.stderr:
                ret['comment'] += 'stderr: %s' % error.stderr.decode('utf-8')
            return ret
        ret['changes']['changes'] = diff
    return ret


def _pull_repo(home_dir, git_dir, branch):
    subprocess.check_call([
        'git',
        '--git-dir', git_dir,
        'fetch',
        '--all',
        '--quiet',
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
        'origin/%s' % branch,
    ], cwd=home_dir)

    return changes


def _clone_new_repo(home_dir, git_dir, repo, branch):
    with tempfile.TemporaryDirectory(dir=home_dir) as tempdir:
        subprocess.check_call([
            'git',
            'clone', repo,
            tempdir,
            # '--quiet',
        ], stderr=subprocess.PIPE)
        subprocess.check_call([
            'git',
            '--git-dir', git_dir,
            'fetch',
            '--all',
            '--quiet',
        ], cwd=home_dir, stderr=subprocess.PIPE)
        os.rename(os.path.join(tempdir, '.git'), git_dir)
        changes = subprocess.check_output([
            'git',
            '--git-dir', git_dir,
            'diff', '-R',
        ], stderr=subprocess.PIPE)
        subprocess.check_call([
            'git',
            '--git-dir', git_dir,
            'checkout', '.'
        ], cwd=home_dir, stderr=subprocess.PIPE)
        return changes
