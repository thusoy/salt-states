import os

try:
    from importlib.machinery import SourceFileLoader
    def load_source(module, path):
        return SourceFileLoader(module, path).load_module()
except ImportError:
    # python 2
    import imp
    def load_source(module, path):
        return imp.load_source(module, path)


dotfiles = load_source('dotfiles', os.path.join(os.path.dirname(__file__), 'init.sls'))

def test_dotfile_string():
    dotfiles.__pillar__ = {
        'users': {
            'testuser': {
                'dotfiles': {
                    '.dotfile': 'pillar:lookup:key',
                },
            },
        },
    }

    ret = dotfiles.run()

    file_managed = ret['dotfiles-testuser-.dotfile']['file.managed']
    assert {'name': '~testuser/.dotfile'} in file_managed
    assert {'user': 'testuser'} in file_managed
    assert {'group': 'testuser'} in file_managed
    assert {'mode': 644} in file_managed
    assert {'makedirs': True} in file_managed
    assert {'contents_pillar': 'pillar:lookup:key'} in file_managed
    assert {'require':  [
        {'user': 'testuser'},
    ]} in file_managed


def test_dotfile_dict():
    dotfiles.__pillar__ = {
        'users': {
            'testuser': {
                'dotfiles': {
                    '.dotfile': {
                        'contents_pillar': 'pillar:lookup:key',
                        'mode': 755,
                    },
                },
            },
        },
    }

    ret = dotfiles.run()

    file_managed = ret['dotfiles-testuser-.dotfile']['file.managed']
    assert {'name': '~testuser/.dotfile'} in file_managed
    assert {'user': 'testuser'} in file_managed
    assert {'group': 'testuser'} in file_managed
    assert {'mode': 755} in file_managed
    assert {'makedirs': True} in file_managed
    assert {'contents_pillar': 'pillar:lookup:key'} in file_managed
    assert {'require':  [
        {'user': 'testuser'},
    ]} in file_managed


def test_dotfile_repo():
    dotfiles.__pillar__ = {
        'users': {
            'testuser': {
                'dotfiles-repo': 'https://example.com/repo',
            },
        },
    }

    ret = dotfiles.run()

    dotfiles_repo = ret['dotfiles-testuser']['dotfiles.repo']
    assert {'user': 'testuser'} in dotfiles_repo
    assert {'repo': 'https://example.com/repo'} in dotfiles_repo
