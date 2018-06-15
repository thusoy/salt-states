#!/usr/bin/env python

import argparse
import datetime
import hashlib
import logging
import os
import shutil
import subprocess
import sys
import tempfile
from collections import namedtuple

import requests

_logger = logging.getLogger(__name__)
_session = requests.Session()

ReleaseBrief = namedtuple('Release', 'version release_date')
ReleaseDetails = namedtuple('ReleaseDetails', 'version release_date url sha256_digest')
ReleaseUrls = namedtuple('ReleaseUrls', 'version release_date url signature_url')


def main():
    args = get_args()
    sanity_check()
    args.action(args)


def sanity_check():
    subprocess.check_output(['gpg', '--version'])


def cli_list(args):
    for release in get_releases():
        print('%s (released %s)' % (release.version, release.release_date.strftime('%Y-%M-%d')))


def cli_info(args):
    release = get_release_info(args.release)
    print('rkt %s (released %s):' % (release.version, release.release_date.strftime('%Y-%M-%d')))
    print('URL: %s' % release.url)
    print('sha256=%s' % release.sha256_digest)


def get_releases():
    response = _session.get('https://api.github.com/repos/rkt/rkt/releases')
    response.raise_for_status()

    for release in response.json():
        version = release['name']
        release_date = parse_iso8601(release['published_at'])
        assets = release.get('assets', [])
        for asset in assets:
            if asset['content_type'] == 'application/vnd.debian.binary-package':
                break
        else:
            _logger.debug('No debian package found for release %s\n' % version)
            continue

        yield ReleaseBrief(version, release_date)


def parse_iso8601(datestr):
    return datetime.datetime.strptime(datestr, '%Y-%m-%dT%H:%M:%SZ')


def get_release_info(release_name):
    release_urls = get_release_urls(release_name)
    return get_verified_release_details(release_urls)


def get_release_urls(release_name):
    response = _session.get('https://api.github.com/repos/rkt/rkt/releases/tags/%s' % release_name)
    response.raise_for_status()

    release = response.json()
    version = release['name']
    release_date = parse_iso8601(release['published_at'])
    assets = release.get('assets', [])

    for asset in assets:
        if asset['content_type'] == 'application/vnd.debian.binary-package':
            url = asset['browser_download_url']
            signature_name = asset['name'] + '.asc'
            break
    else:
        _logger.warning('No debian package found for release %s\n' % version)
        return

    for asset in assets:
        if asset['name'] == signature_name:
            signature_url = asset['browser_download_url']
            break
    else:
        raise ValueError('No signature found for debian package for %s' % version)

    return ReleaseUrls(version, release_date, url, signature_url)


def get_verified_release_details(release_urls):
    download, hexdigest = download_url(release_urls.url)
    signature, _ = download_url(release_urls.signature_url)
    key_path = os.path.join(os.path.dirname(__file__), 'release-key.asc')
    verify_signature(key_path, signature.name, download.name)
    return ReleaseDetails(release_urls.version, release_urls.release_date,
        release_urls.url, hexdigest)


def verify_signature(key_path, signature_path, data_path):
    tempdir = tempfile.mkdtemp()
    subprocess.check_call(['gpg',
        '--homedir', tempdir,
        '--quiet',
        '--import', key_path,
    ])
    output = subprocess.check_output(['gpg',
        '--homedir', tempdir,
        '--status-fd', '1',
        '--verify',
        '--quiet',
        '--trust-model', 'always',
        signature_path,
        data_path,
    ])
    shutil.rmtree(tempdir)
    if not 'GOODSIG' in output and 'VALIDSIG' in output:
        raise ValueError('Failed signature validation')


def download_url(url):
    response = _session.get(url, stream=True)
    response.raise_for_status()
    destination = tempfile.NamedTemporaryFile()
    digest = hashlib.sha256()

    # chunk_size=None sets whatever chunk size it arrives with from the network
    for chunk in response.iter_content(chunk_size=None):
        destination.write(chunk)
        digest.update(chunk)

    destination.seek(0)
    return destination, digest.hexdigest()


def get_args():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command',
        title='Commands',
        help='What do you want to do?')

    add_list_parser(subparsers)
    add_info_parser(subparsers)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    return args


def add_list_parser(subparsers):
    parser = subparsers.add_parser('list', help='List releases')
    parser.set_defaults(action=cli_list)


def add_info_parser(subparsers):
    parser = subparsers.add_parser('info', help='Get info about a single release')
    parser.add_argument('release', help='Which release to get info about, like v1.15.0')
    parser.set_defaults(action=cli_info)

# TODO: Add quick helper for "latest" that uses GET /repos/:owner/:repo/releases/latest
# TODO: Configure logger and log rate limiting remaining
# TODO: Possibly enable setting auth to get around public ratelimit

def configure_logger(level):
    logging.basicConfig(level=logging.DEBUG,
        format="%(asctime)s %(levelname)-5s %(name)-10s %(threadName)-10s %(message)s")


if __name__ == '__main__':
    main()
