'''
Load pillar values from terraform.

Configure like this:

ext_pillar:
    - terraform:
        terraform_directory: /srv/terraform
        access_control:
            '*':
                - 'public_*'
            '*.postgres':
                - 'postgres_*'

The access control dictionary should be a map from a minion glob to a list of
globs for which keys to expose the given minion.

If there's any environment variables you need to set, you can use the environment
key to provide a dict with values to set before calling out to terraform. This
can be convenient to set where to find credentials and similar.
'''

import fnmatch
import json
import logging
import os
import subprocess


_logger = logging.getLogger(__name__)


def ext_pillar(
        minion_id,
        pillar,
        terraform_directory=None,
        access_control=None,
        environment=None,
        **kwargs):
    if terraform_directory is None or access_control is None:
        _logger.warning('terraform pillar extension is not configured with '
            'terraform_directory and access_control, not providing any pillar values')
        return {}

    key_globs = extract_minion_key_globs(minion_id, access_control)
    if not key_globs:
        return {}

    os.environ.update(environment or {})

    terraform_values = get_terraform_output(terraform_directory)

    ret = {}

    for key, value in terraform_values.items():
        for key_glob in key_globs:
            if fnmatch.fnmatch(key, key_glob):
                ret[key] = value
                break

    return {
        'terraform': ret,
    }


def extract_minion_key_globs(minion_id, access_control):
    ret = []

    for minion_glob, key_globs in access_control.items():
        if fnmatch.fnmatch(minion_id, minion_glob):
            ret.extend(key_globs)

    return ret


def get_terraform_output(terraform_directory):
    output = subprocess.check_output([
        'terraform',
        'output',
        '-json',
    ], cwd=terraform_directory)
    parsed_output = json.loads(output)
    ret = {}
    for key, data in parsed_output.items():
        ret[key] = data['value']
    return ret


