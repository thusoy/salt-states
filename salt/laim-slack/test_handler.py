import os
import tempfile
import textwrap

import pytest

try:
    from importlib.machinery import SourceFileLoader
    def load_source(module, path):
        return SourceFileLoader(module, path).load_module()
    module = load_source('handler', os.path.join(os.path.dirname(__file__), 'handler.py'))

    # imports specific to py3
    from unittest import skipIf, mock
    from email.message import EmailMessage
except ImportError:
    # python 2
    pytestmark = pytest.mark.skip


def test_handle_slack(handler):
    message = EmailMessage()
    message.set_content('test message')
    message['Subject'] = 'Some subject'
    handler.session = mock.Mock()
    handler.session.post.return_value.json.return_value = {'ok': True}
    handler.handle_message('root', ['root'], message)
    handler.session.post.assert_called_once_with('https://slack.com/api/chat.postMessage', json=mock.ANY)


@pytest.fixture
def handler(temp_config):
    with mock.patch('laim.util.os') as os_mock:
        with mock.patch('pwd.getpwnam') as getpwnam_mock:
            with mock.patch('laim.LaimController'):
                ret = module.SlackHandler(config_file=temp_config)
    return ret


@pytest.fixture
def temp_config():
    with tempfile.NamedTemporaryFile() as config:
        config.write(textwrap.dedent('''
            slack-token: foo secret
            slack-channel-id: testid
        ''').encode('utf-8'))
        config.flush()
        yield config.name
