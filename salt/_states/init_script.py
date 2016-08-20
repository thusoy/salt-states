import os
import subprocess

def get_init_system():
    """ Return the name of the init system running on the machine.

    The default is to check for systemd, then upstart, and if neither is found, assume sysvinit.
    """
    real_init_path = os.path.realpath('/sbin/init')
    if real_init_path == '/lib/systemd/systemd':
        return 'systemd'
    init_system = subprocess.check_output('ps aux | grep -o "[u]pstart" -m 1 || echo sysvinit', shell=True)
    return init_system.strip()


def managed(name, **kwargs):
    """ Make sure an init script is present. Set the name of the service, and a file
    source for each of the different init systems you want to support.
    """
    init_system = get_init_system()
    if init_system == 'upstart':
        kwargs['name'] = '/etc/init/%s.conf' % name
        kwargs['mode'] = '0644'
    elif init_system == 'sysvinit':
        kwargs['name'] = '/etc/init.d/%s' % name
        kwargs['mode'] = '0755'
    elif init_system == 'systemd':
        if 'user_script' in kwargs:
            kwargs['name'] = '/home/%s/.config/systemd/user/%s.service' % (
                kwargs['user_script'], name)
            kwargs['makedirs'] = True
        else:
            kwargs['name'] = '/etc/systemd/system/%s.service' % name
        kwargs['mode'] = '0644'

    file_source = kwargs.pop(init_system, None)
    ret = {'name': name, 'changes': {}, 'result': False, 'comment': ''}

    if file_source is None:
        ret['comment'] = 'No source file for present init system given: %s' % init_system
        return ret

    kwargs['source'] = file_source
    state_ret = __salt__['state.single']('file.managed', **kwargs)
    file_ret = state_ret.values()[0]
    ret['comment'] = file_ret['comment']
    ret['result'] = file_ret['result']
    ret['changes'] = file_ret['changes']
    return ret
