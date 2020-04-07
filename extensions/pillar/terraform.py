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
globs for which keys to expose the given minion. `terraform_directory` should be
the directory to execute terraform from. Alternatively you can set
`terraform_output_file` to a path where the terraform output has already been
written to disk as json. This can be convenient if you don't want the saltmaster
to have access to the full terraform state.

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
        terraform_output_file=None,
        access_control=None,
        environment=None,
        **kwargs):
    if access_control is None:
        _logger.warning('terraform pillar extension is not configured with '
            'access_control, not providing any pillar values')
        return {}

    if terraform_directory is None and terraform_output_file is None:
        _logger.warning('terraform pillar extension is not configured with '
            'terraform_directory or terraform_output_file, not providing any '
            'pillar values')
        return {}

    key_globs = extract_minion_key_globs(minion_id, access_control)
    if not key_globs:
        return {}

    os.environ.update(environment or {})

    terraform_values = get_terraform_output(terraform_directory, terraform_output_file)

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


def get_terraform_output(terraform_directory, terraform_output_file):
    if terraform_directory:
        output = subprocess.check_output([
            'terraform',
            'output',
            '-json',
        ], cwd=terraform_directory)
    else:
        with open(terraform_output_file, 'rb') as fh:
            output = fh.read()

    parsed_output = json.loads(output.decode('utf-8'))
    ret = {}
    for key, data in parsed_output.items():
        ret[key] = data['value']
    return ret
