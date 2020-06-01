#!py

try:
    basestring = basestring
except NameError:
    # Python 3
    basestring = str

def run():
    states = {
        'include': [
            'users',
        ]
    }
    for username, user_values in __pillar__.get('users', {}).items():
        dotfiles = user_values.get('dotfiles')
        if isinstance(dotfiles, basestring):
            states['dotfiles-%s' % username] = {
                'dotfiles.repo': [
                    {'repo': dotfiles},
                    {'user': username},
                ]
            }
        else:
            for filename, dotfile_spec in dotfiles.items():
                file_managed = {
                    'name': '~%s/%s' % (username, filename),
                    'user': username,
                    'group': username,
                    'makedirs': True,
                    'mode': 644,
                    'require': [
                        {'user': username},
                    ],
                }

                if isinstance(dotfile_spec, basestring):
                    file_managed['contents_pillar'] = dotfile_spec
                else:
                    # Assume it's a dict, overwrite all default values with the given ones
                    file_managed.update(dotfile_spec)

                file_managed_list = []
                for key, value in file_managed.items():
                    file_managed_list.append({key: value})

                states['dotfiles-%s-%s' % (username, filename)] = {
                    'file.managed': file_managed_list,
                }

    return states
