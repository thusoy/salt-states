# Identical to file.patch, but allows patch file to be specified by patch parameter
# instead of loading from file, and doesn't use hash to check for correctness.

import os
import salt.utils
import tempfile

import logging

log = logging.getLogger(__name__)

def _error(ret, err_msg):
    ret['result'] = False
    ret['comment'] = err_msg
    return ret

def _check_file(name):
    ret = True
    msg = ''

    if not os.path.isabs(name):
        ret = False
        msg = 'Specified file {0} is not an absolute path'.format(name)
    elif not os.path.exists(name):
        ret = False
        msg = '{0}: file not found'.format(name)

    return ret, msg

def apply(name,
          source=None,
          patch=None,
          options='',
          dry_run_first=True,
          **kwargs):
    '''
    Apply a patch to a file or directory.
    .. note::
        A suitable ``patch`` executable must be available on the minion when
        using this state function.
    name
        The file or directory to which the patch will be applied.
    source
        The source patch to download to the minion, this source file must be
        hosted on the salt master server. If the file is located in the
        directory named spam, and is called eggs, the source string is
        salt://spam/eggs. A source is required.
    options
        Extra options to pass to patch.
    dry_run_first : ``True``
        Run patch with ``--dry-run`` first to check if it will apply cleanly.
    saltenv
        Specify the environment from which to retrieve the patch file indicated
        by the ``source`` parameter. If not provided, this defaults to the
        environment from which the state is being executed.
    Usage:
    .. code-block:: yaml
        # Equivalent to ``patch --forward /opt/file.txt file.patch``
        /opt/file.txt:
          file.patch:
            - source: salt://file.patch
            - hash: md5=e138491e9d5b97023cea823fe17bac22
    '''
    if 'env' in kwargs:
        salt.utils.warn_until(
            'Oxygen',
            'Parameter \'env\' has been detected in the argument list.  This '
            'parameter is no longer used and has been replaced by \'saltenv\' '
            'as of Salt Carbon.  This warning will be removed in Salt Oxygen.'
            )
        kwargs.pop('env')

    name = os.path.expanduser(name)

    ret = {'name': name, 'changes': {}, 'result': False, 'comment': ''}
    if not name:
        return _error(ret, 'Must provide name to file.patch')
    check_res, check_msg = _check_file(name)
    if not check_res:
        return _error(ret, check_msg)
    if source:
        # get cached file or copy it to cache

        cached_source_path = __salt__['cp.cache_file'](source, __env__)
        if not cached_source_path:
            ret['comment'] = ('Unable to cache {0} from saltenv {1!r}'
                              .format(source, __env__))
            return ret

        log.debug('State patch.applied cached source %s -> %s',
            source, cached_source_path)
    elif patch:
        cached_source_path = tempfile.NamedTemporaryFile(delete=False)
        cached_source_path.write(patch)
        cached_source_path.close()
    else:
        return _error(ret, 'Source or patch is required')


    if dry_run_first or __opts__['test']:
        ret['changes'] = __salt__['file.patch'](
            name, cached_source_path, options=options, dry_run=True
        )
        if __opts__['test']:
            ret['comment'] = 'File {0} will be patched'.format(name)
            ret['result'] = None
            return ret
        if ret['changes']['retcode']:
            return ret

    ret['changes'] = __salt__['file.patch'](
        name, cached_source_path, options=options
    )
    ret['result'] = True if ret['changes']['retcode'] == 0 else False
    return ret
