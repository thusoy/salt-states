#!py

import re

# Not pinning the tags used since there's currently a mismatch with h2 opening tags closed by h3
VERSION_RE = re.compile(r'>Slack (\d+\.\d+\.\d+)<')

def run():
    # No apt repo for slack unfortunately, thus parse the release notes to get
    # the latest version and install the deb manually
    slack = __pillar__.get('slack', {})
    version = slack.get('version', 'latest')
    if version == 'latest':
        release_notes = __salt__['http.query']('https://slack.com/release-notes/linux')
        match = VERSION_RE.search(release_notes['body'])
        if not match:
            raise ValueError('Failed to find any versions in slack release notes')
        version = match.group(1)

    return {
        'slack': {
            'pkg.installed': [{
                'sources': [{
                    'slack-desktop': 'https://downloads.slack-edge.com/linux_releases/slack-desktop-%s-amd64.deb' % version,
                }]
            }]
        }
    }
