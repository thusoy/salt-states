import datetime
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
        brotli (1.0.7-2+deb10u1) buster-security; urgency=medium
         * CVE-2020-8927
        -- Moritz Mühlenhoff <jmm@debian.org>  Wed, 25 Nov 2020 22:33:28 +0100
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
            'host': '{{ grains.id }}',
            'subject': 'apt-listchanges: changelogs for test',
            'to': ['root'],
            'from': 'root',
            'package': 'brotli',
            'version': '1.0.7-2+deb10u1',
            'distributions': 'buster-security',
            'meta.urgency': 'medium',
            'maintainer': 'Moritz Mühlenhoff <jmm@debian.org>',
            'release.spec':  'Wed, 25 Nov 2020 22:33:28 +0100',
            'release.age_seconds': mock.ANY,
        },
    }]


def test_parse_upgrade(handler):
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

    datetime_mock = lambda: datetime.datetime(2020, 7, 31, 12, 0, 0, tzinfo=datetime.timezone.utc)
    with mock.patch.object(module, 'utcnow', datetime_mock):
        parsed = module.parse_package_upgrades(message)
    assert len(parsed) == 2

    assert parsed[0]['package'] == 'grub-efi-amd64-signed'
    assert parsed[0]['version'] == '1+2.02+dfsg1+20+deb10u2'
    assert parsed[0]['distributions'] == 'buster-security'
    assert parsed[0]['meta.urgency'] == 'high'
    assert parsed[0]['maintainer'] == 'Debian signing service <ftpmaster@debian.org>'
    assert parsed[0]['release.spec'] == 'Thu, 30 Jul 2020 20:19:53 +0100'
    assert parsed[0]['release.age_seconds'] == 60007

    assert parsed[1]['package'] == 'grub2'
    assert parsed[1]['version'] == '2.02+dfsg1-20+deb10u2'
    assert parsed[1]['distributions'] == 'buster-security'
    assert parsed[1]['meta.urgency'] == 'high'
    assert parsed[1]['maintainer'] == 'Colin Watson <cjwatson@debian.org>'
    assert parsed[1]['release.spec'] == 'Thu, 30 Jul 2020 20:19:53 +0100'
    assert parsed[0]['release.age_seconds'] == 60007


def test_parse_upgrade_trailer_empty(handler):
    message = EmailMessage()
    message.set_content(textwrap.dedent('''\
        grub-efi-amd64-signed (1+2.02+dfsg1+20+deb10u2) buster-security; urgency=high
         * Update to grub2 2.02+dfsg1-20+deb10u2
        -- Debian signing service <ftpmaster@debian.org>  Thu, 30 Jul 2020 20:19:53 +0100

    '''))

    parsed = module.parse_package_upgrades(message)

    assert len(parsed) == 1


def test_parse_upgrade_trailer(handler):
    message = EmailMessage()
    message.set_content(textwrap.dedent('''\
        grub-efi-amd64-signed (1+2.02+dfsg1+20+deb10u2) buster-security; urgency=high
         * Update to grub2 2.02+dfsg1-20+deb10u2
        -- Debian signing service <ftpmaster@debian.org>  Thu, 30 Jul 2020 20:19:53 +0100
        invalid changelog entry here
    '''))

    with pytest.raises(ValueError):
        parsed = module.parse_package_upgrades(message)


def test_parse_upgrade_incomplete(handler):
    message = EmailMessage()
    message.set_content(textwrap.dedent('''\
        grub-efi-amd64-signed (1+2.02+dfsg1+20+deb10u2) buster-security; urgency=high
         * Update to grub2 2.02+dfsg1-20+deb10u2
    '''))

    with pytest.raises(ValueError):
        parsed = module.parse_package_upgrades(message)


def test_parse_upgrade_empty(handler):
    message = EmailMessage()
    message.set_content(textwrap.dedent('''\
        grub-efi-amd64-signed (1+2.02+dfsg1+20+deb10u2) buster-security; urgency=high'''))

    with pytest.raises(ValueError):
        parsed = module.parse_package_upgrades(message)


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
