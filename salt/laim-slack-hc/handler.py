import datetime
import os
import re
import textwrap

import requests
from laim import Laim

PACKAGE_SPEC_RE = re.compile(r'^(?P<package>.+) \((?P<version>.+)\) (?P<distributions>.+);(?P<metadata>.*)$')
MAINTAINER_SPEC_RE = re.compile(r'^-- (?P<maintainer>.+)  (?P<date>.+)$')


class SlackHoneycombHandler(Laim):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.session = requests.Session()
        self.session.headers.update({
            # Explicitly set charset to avoid warnings from slack
            'Content-Type': 'application/json; charset=utf-8',
        })
        self.channel_id = self.config['slack-channel-id']
        self.dataset = self.config['honeycomb-dataset']
        self.hostname = '{{ grains.id }}' # TODO: Move this to the `laim` state and always include in config


    def handle_message(self, sender, recipients, message):
        subject = message.get('Subject', '')
        is_plaintext = message.get_content_type() == 'text/plain'
        if subject.startswith('apt-listchanges: changelogs for ') and is_plaintext:
            try:
                self.post_to_honeycomb(recipients, message)
                return
            except ValueError:
                pass

        self.post_to_slack(recipients, message)


    def post_to_honeycomb(self, recipients, message):
        upgrades = parse_package_upgrades(message)
        context = {
            'service': 'laim',
            'host': self.hostname,
            'action': 'package-upgrade',
            'to': recipients,
            'from': message.get('From'),
            'subject': message.get('Subject'),
        }
        body = [{'data': dict(context, **upgrade)} for upgrade in upgrades]
        response = self.session.post('https://api.honeycomb.io/1/batch/%s' % self.dataset,
            json=body,
            headers={
                'X-Honeycomb-Team': self.config['honeycomb-key'],
            })
        response.raise_for_status()


    def post_to_slack(self, recipients, message):
        response = self.session.post('https://slack.com/api/chat.postMessage', json={
            'channel': self.channel_id,
            'text': textwrap.dedent('''\
                `%s` received mail for %s
                *From*: %s
                *To*: %s
                *Subject*: %s

                %s
            ''') % (
                self.hostname,
                ', '.join(recipients),
                message.get('From'),
                message.get('To'),
                message.get('Subject'),
                message.get_payload(),
            ),
        }, headers={
            'Authorization': 'Bearer %s' % self.config['slack-token'],
        })
        body = response.json()
        if not body['ok']:
            raise ValueError('Failed to forward mail to slack, got %r', body)


def parse_package_upgrades(message):
    message_body = message.get_payload()
    message_lines = message_body.split('\n')
    message_iterator = iter(message_lines)
    upgrades = []
    line = next(message_iterator)
    unparsed_content = False
    while True:
        try:
            spec_match = PACKAGE_SPEC_RE.match(line)
            if spec_match:
                spec_dict = spec_match.groupdict()
                upgrade = {
                    'package': spec_dict['package'],
                    'distributions': spec_dict['distributions'],
                    'version': spec_dict['version'],
                }
                for meta in spec_dict['metadata'].split(','):
                    key, val = meta.strip().split('=', 1)
                    upgrade['meta.%s' % key] = val

                line = next(message_iterator)
                while True:
                    maintainer_match = MAINTAINER_SPEC_RE.match(line)
                    if maintainer_match:
                        maintainer_dict = maintainer_match.groupdict()
                        upgrade.update({
                            'maintainer': maintainer_dict['maintainer'],
                            'release.spec': maintainer_dict['date'],
                            'release.age_seconds': parse_release_spec_age(maintainer_dict['date']),
                        })
                        break
                    try:
                        line = next(message_iterator)
                    except StopIteration:
                        raise ValueError('Invalid changelog format: Missing maintainer line')

                upgrades.append(upgrade)
            elif line:
                # Invalid message format, raise so that this can be logged
                raise ValueError('Invalid changelog format: Trailing data')
            line = next(message_iterator)
        except StopIteration:
            break

    return upgrades


def parse_release_spec_age(release_spec):
    parsed = datetime.datetime.strptime(release_spec, '%a, %d %b %Y %H:%M:%S %z')
    return int((utcnow() - parsed).total_seconds())


def utcnow():
    # Separate method to simplify mocking
    return datetime.datetime.now(datetime.timezone.utc)


if __name__ == '__main__':
    handler = SlackHandler()
    handler.run()
