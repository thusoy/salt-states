#!/usr/bin/env python3

import argparse
import binascii
import os
import pwd
import subprocess
import sys
import tempfile

import dns.tsigkeyring
import yaml

sys.path.insert(0, '.')
from acme_tiny_dns import get_crt


def main():
    args = get_args()
    config = load_config(args.config)
    with tempfile.NamedTemporaryFile() as account_key_fh:
        account_key_fh.write(config['account-key'].encode('utf-8'))
        account_key_fh.flush()

        for zone in config.get('zones', []):
            acme_tiny_args = get_acme_tiny_args(config, zone)
            for certificate in zone.get('certificates', []):
                hostname = certificate['hostname']
                create_cert(hostname, account_key_fh.name, acme_tiny_args,
                    config['saltmaster-user'])


def create_cert(hostname, account_key_path, acme_tiny_args, key_read_user):
    key_generators = [
        ('ecdsa', create_ecdsa_key),
        ('rsa', create_rsa_key),
    ]
    output_dir = '/var/lib/acme-dns'
    for key_type, key_generator in key_generators:
        key = key_generator()
        csr = create_csr(key, hostname)
        with tempfile.NamedTemporaryFile() as fh:
            fh.write(csr)
            fh.flush()
            cert = get_crt(account_key_path, fh.name, **acme_tiny_args)

        cert_path = os.path.join(output_dir, '%s.%s.crt' % (hostname, key_type))
        with open(cert_path, 'w') as fh:
            fh.write(cert)

        key_path = os.path.join(output_dir, '%s.%s.pem' % (hostname, key_type))
        write_private_key(key.decode('utf-8'), key_path, key_read_user)


def load_config(config_file_path):
    with open(config_file_path) as fh:
        return yaml.safe_load(fh)


def get_acme_tiny_args(config, zone):
    args = {
        'contact_mail': config['contact'],
        'dns_zone_update_server': zone['update-server'],
        'dns_zone_keyring': dns.tsigkeyring.from_text({
            zone['key-name']: zone['key-secret'],
        }),
        'dns_update_algo': zone['key-algorithm'],
    }
    dns_zone = zone.get('zone')
    if dns_zone:
        args['dns_zone'] = dns_zone

    return args


def write_private_key(private_key, destination, key_read_user):
    temp_filename = '.' + binascii.hexlify(os.urandom(16)).decode('utf-8')
    tempfile = os.path.join(os.path.dirname(destination), temp_filename)
    with secure_open_file(tempfile, 'w') as fh:
        if key_read_user != 'root':
            read_user_gid = pwd.getpwnam(key_read_user).pw_gid
            os.fchown(fh.fileno(), -1, read_user_gid)
        fh.write(private_key)
    os.rename(tempfile, destination)


def secure_open_file(filename, mode='wb'):
    """ Create a new file with 440 permissions, ensuring exclusive access.

    The motivation is to avoid information disclosure if any other users have
    access to the target directory and can create files. We thus need to ensure
    that when we open a file it's a new file that no-one else already has a file
    descriptor for. For subsequent accesses the permissions are set to 400,
    ensuring that the file is never modified directly, but can only be updated
    by replacing the entire file, forcing us to stay thread-safe.

    We could also have used the O_TMPFILE flag to avoid having a filesystem
    entry before replacing the file at all, but filesystem support for this is
    a bit spotty and requires another python package to access the linkat(2)
    function (and linux kernel 3.11 or later).
    """
    perms = 0o440
    fd = os.open(filename, os.O_CREAT | os.O_WRONLY | os.O_EXCL, perms)
    handle = os.fdopen(fd, mode)

    return handle


def create_rsa_key():
    return subprocess.check_output([
        'openssl',
        'genrsa',
        '2048',
    ])


def create_ecdsa_key():
    return subprocess.check_output([
        'openssl',
        'ecparam',
        '-name', 'prime256v1',
        '-genkey',
    ])


def create_csr(private_key, domain):
    with tempfile.NamedTemporaryFile() as fh:
        fh.write(private_key)
        fh.flush()

        csr = subprocess.check_output([
            'openssl',
            'req',
            '-new',
            '-sha256',
            '-key', fh.name,
            '-subj', "/CN=%s" % domain,
        ])

    return csr


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', default='/etc/acme-dns.yaml')
    return parser.parse_args()


if __name__ == '__main__':
    main()
