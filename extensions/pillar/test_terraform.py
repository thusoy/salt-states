import json
import os
import sys
import tempfile
try:
    from unittest import mock
except:
    import mock

sys.path.insert(0, os.path.dirname(__file__))

from terraform import ext_pillar as uut, get_terraform_output


def test_unconfigured():
    assert uut('some_minion', {}) == {}


def test_get_terraform_output():
    with mock.patch('subprocess.check_output') as subprocess_mock:
        subprocess_mock.return_value = json.dumps({
            'output_variable': {
                'sensitive': False,
                'type': 'string',
                'value': 'variable_contents',
            }
        }).encode('utf-8')

        ret = get_terraform_output('/some_dir', None)

        subprocess_mock.assert_called_with(['terraform', 'output', '-json'], cwd='/some_dir')
        assert ret == {
            'output_variable': 'variable_contents',
        }


def test_no_access():
    ret = uut('some_minion', {}, terraform_directory='/tmp/terraform', access_control={
        '*.namespace': [
            'namespace_*',
        ],
    })

    assert ret == {}


def test_partial_access():
    with mock.patch('terraform.get_terraform_output') as output_mock:
        output_mock.return_value = {
            'some_namespace_key': 'permitted value',
            'other_namespace_key': 'denied value',
        }

        ret = uut('some_minion', {}, terraform_directory='/tmp/terraform', access_control={
            '*': [
                'some_namespace_*',
            ],
        })

        assert ret == {
            'terraform': {
                'some_namespace_key': 'permitted value',
            }
        }


def test_terraform_output_file():
    output_file = tempfile.NamedTemporaryFile(delete=False)
    output_file.write(json.dumps({
        'output_variable': {
            'sensitive': False,
            'type': 'string',
            'value': 'some variable',
        }
    }).encode('utf-8'))
    output_file.close()

    ret = get_terraform_output(None, output_file.name)
    assert ret == {
        'output_variable': 'some variable',
    }


def test_terraform_output_file_missing():
    ret = get_terraform_output(None, '/nonexisting')
    assert ret == {}
