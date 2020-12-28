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
    handler.session.post.assert_called_once_with('https://slack.com/api/chat.postMessage',
        json=mock.ANY, headers=mock.ANY)


def test_handle_changelog(handler):
    message = EmailMessage()
    message.set_content(textwrap.dedent('''\
        grub-efi-amd64-signed (1+2.02+dfsg1+20+deb10u2) buster-security; urgency=high
         * Update to grub2 2.02+dfsg1-20+deb10u2
        -- Debian signing service <ftpmaster@debian.org>  Thu, 30 Jul 2020 20:19:53 +0100
        grub2 (2.02+dfsg1-20+deb10u2) buster-security; urgency=high
         * Fix a regression caused by "efi: fix some malformed device path
           arithmetic errors" (thanks, Chris Coulson and Steve McIntyre; closes:
           #966554).
        -- Colin Watson <cjwatson@debian.org>  Thu, 30 Jul 2020 20:19:53 +0100
        '''))
    message['Subject'] = 'apt-listchanges: changelogs for test'
    message['From'] = 'root'
    handler.session = mock.Mock()
    handler.session.post.return_value.json.return_value = {'ok': True}
    handler.handle_message('root', ['root'], message)
    handler.session.post.assert_called_once_with('https://api.honeycomb.io/1/batch/test-dataset',
        json=mock.ANY, headers=mock.ANY)
    body = handler.session.post.call_args[1]['json']
    assert body == [{
        'data': {
            'service': 'laim',
            'action': 'package-upgrade',
            'package': 'grub-efi-amd64-signed',
            'version': '1+2.02+dfsg1+20+deb10u2',
            'distributions': 'buster-security',
            'meta.urgency': 'high',
            'maintainer': 'Debian signing service <ftpmaster@debian.org>',
            'release.spec': 'Thu, 30 Jul 2020 20:19:53 +0100',
            'host': '{{ grains.id }}',
            'subject': 'apt-listchanges: changelogs for test',
            'to': ['root'],
            'from': 'root',
        },
    }, {
        'data': {
            'service': 'laim',
            'action': 'package-upgrade',
            'package': 'grub2',
            'version': '2.02+dfsg1-20+deb10u2',
            'distributions': 'buster-security',
            'meta.urgency': 'high',
            'maintainer': 'Colin Watson <cjwatson@debian.org>',
            'release.spec': 'Thu, 30 Jul 2020 20:19:53 +0100',
            'host': '{{ grains.id }}',
            'subject': 'apt-listchanges: changelogs for test',
            'to': ['root'],
            'from': 'root',
        },
    }]


def test_slack_fallback(handler):
    message = EmailMessage()
    message['Subject'] = 'apt-listchanges: changelogs for test'
    with mock.patch.object(handler, 'post_to_honeycomb') as hc_mock:
        with mock.patch.object(handler, 'post_to_slack') as slack_mock:
            hc_mock.side_effect = ValueError('foo')
            handler.handle_message(None, None, message)
            hc_mock.assert_called_once_with(None, message)
            slack_mock.assert_called_once_with(None, message)


@pytest.fixture
def handler(temp_config):
    with mock.patch('laim.util.os') as os_mock:
        with mock.patch('pwd.getpwnam') as getpwnam_mock:
            with mock.patch('laim.LaimController'):
                ret = module.SlackHoneycombHandler(config_file=temp_config)
    return ret


@pytest.fixture
def temp_config():
    with tempfile.NamedTemporaryFile() as config:
        config.write(textwrap.dedent('''
            slack-token: foo secret
            slack-channel-id: testid

            honeycomb-dataset: test-dataset
            honeycomb-key: testkey
        ''').encode('utf-8'))
        config.flush()
        yield config.name
