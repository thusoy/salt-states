import os
import tempfile
import subprocess
import shutil

import salt.utils.path


DOTFILES_GIT_DIR = '.dotfiles'


def __virtual__():
    return salt.utils.path.which('git') is not None


def repo(name, repo, user):
    ret = {
        'name': name,
        'comment': '',
        'result': True,
        'changes': {},
    }
    home_dir = os.path.expanduser('~%s' % user)
    git_dir = os.path.expanduser('~%s/%s' % (user, DOTFILES_GIT_DIR))
    if os.path.exists(git_dir):
        changes, comment = _pull_repo(home_dir, git_dir)
        if changes:
            ret['changes']['changes'] = changes
        ret['comment'] = comment
    else:
        _clone_new_repo(home_dir, git_dir, repo)
        ret['changes']['new'] = 'Cloned repo %s' % repo
    return ret


def _pull_repo(home_dir, git_dir):
    old_head = subprocess.check_output([
        'git',
        '--git-dir', git_dir,
        'rev-parse', 'HEAD'
    ], cwd=home_dir)
    proc = subprocess.run([
        'git',
        '--git-dir', git_dir,
        'pull',
    ], cwd=home_dir, check=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    new_head = subprocess.check_output([
        'git',
        '--git-dir', git_dir,
        'rev-parse', 'HEAD'
    ], cwd=home_dir)

    changes = ''
    if new_head != old_head:
         changes = proc.stdout.decode('utf-8')
    comment = proc.stderr.decode('utf-8')
    return changes, comment


def _clone_new_repo(home_dir, git_dir, repo):
    with tempfile.TemporaryDirectory(dir=home_dir) as tempdir:
        subprocess.check_call([
            'git',
            'clone', repo,
            tempdir,
        ])
        os.rename(os.path.join(tempdir, '.git'), git_dir)
        subprocess.check_call([
            'git',
            '--git-dir', git_dir,
            'checkout', '.'
        ], cwd=home_dir)
