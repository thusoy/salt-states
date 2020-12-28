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
            'Authorization': 'Bearer %s' % self.config['slack-token'],
            'X-Honeycomb-Team': self.config['honeycomb-key'],
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
            self.post_to_honeycomb(recipients, message)
        else:
            self.post_to_slack(recipients, message)


    def post_to_honeycomb(self, recipients, message):
        message_body = message.get_payload()
        context = {
            'service': 'laim',
            'host': self.hostname,
            'action': 'package-upgrade',
            'to': recipients,
            'from': message.get('From'),
            'subject': message.get('Subject'),
        }
        message_lines = message_body.split('\n')
        message_iterator = iter(message_lines)
        updates = []
        line = next(message_iterator)
        while True:
            try:
                spec_match = PACKAGE_SPEC_RE.match(line)
                if spec_match:
                    spec_dict = spec_match.groupdict()
                    update = {
                        'package': spec_dict['package'],
                        'distributions': spec_dict['distributions'],
                        'version': spec_dict['version'],
                    }
                    for meta in spec_dict['metadata'].split(','):
                        key, val = meta.strip().split('=', 1)
                        update['meta.%s' % key] = val

                    update.update(context)
                    line = next(message_iterator)
                    while True:
                        maintainer_match = MAINTAINER_SPEC_RE.match(line)
                        if maintainer_match:
                            maintainer_dict = maintainer_match.groupdict()
                            update.update({
                                'maintainer': maintainer_dict['maintainer'],
                                'release.spec': maintainer_dict['date'],
                            })
                            break
                        line = next(message_iterator)

                    updates.append({
                        'data': update,
                    })

                line = next(message_iterator)
            except StopIteration:
                break

        response = self.session.post('https://api.honeycomb.io/1/batch/%s' % self.dataset, json=updates)


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
        })
        body = response.json()
        if not body['ok']:
            raise ValueError('Failed to forward mail to slack, got %r', body)


if __name__ == '__main__':
    handler = SlackHandler()
    handler.run()
