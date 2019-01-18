#!/usr/bin/env python
# Copyright Daniel Roesler, under MIT license, see LICENSE at github.com/diafygi/acme-tiny
from __future__ import print_function

import argparse, subprocess, json, os, sys, base64, binascii, time, hashlib, re, copy, textwrap, logging

import pprint
import six
import socket
import traceback

import dns.message
import dns.name
import dns.query
import dns.rcode
import dns.rdataclass
import dns.rdatatype
import dns.resolver
import dns.update
import dns.tsigkeyring

from six.moves.urllib.request import urlopen, Request

TEST_CA = "https://acme-staging-v02.api.letsencrypt.org/directory"
PROD_CA = "https://acme-v02.api.letsencrypt.org/directory"

LOGGER = logging.getLogger(__name__)
LOGGER.addHandler(logging.StreamHandler())
LOGGER.setLevel(logging.INFO)

def get_crt(account_key, csr, skip_check=False, log=LOGGER, CA=PROD_CA, contact=None,
            dns_zone_update_server=None, dns_zone_keyring=None, dns_zone=None, dns_update_algo=None):
    directory, acct_headers, alg, jwk = None, None, None, None # global variables

    # helper functions - base64 encode for jose spec
    def _b64(b):
        return base64.urlsafe_b64encode(b).decode('utf8').replace("=", "")

    # helper function - run external commands
    def _cmd(cmd_list, stdin=subprocess.PIPE, cmd_input=None, err_msg="Command Line Error"):
        proc = subprocess.Popen(cmd_list, stdin=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
        out, err = proc.communicate(cmd_input)
        if proc.returncode != 0:
            raise IOError("{0}\n{1}".format(err_msg, err))
        return out

    # helper function - make request and automatically parse json response
    def _do_request(url, data=None, err_msg="Error", depth=0):
        try:
            resp = urlopen(Request(url, data=data, headers={"Content-Type": "application/jose+json", "User-Agent": "acme-tiny-dns"}))
            resp_data, code, headers = resp.read().decode("utf8"), resp.getcode(), resp.headers
        except IOError as e:
            resp_data = e.read().decode("utf8") if hasattr(e, "read") else str(e)
            code, headers = getattr(e, "code", None), {}
        try:
            resp_data = json.loads(resp_data) # try to parse json results
        except ValueError:
            pass # ignore json parsing errors
        if depth < 100 and code == 400 and resp_data['type'] == "urn:ietf:params:acme:error:badNonce":
            raise IndexError(resp_data) # allow 100 retrys for bad nonces
        if code not in [200, 201, 204]:
            raise ValueError("{0}:\nUrl: {1}\nResponse Code: {2}\nResponse: {3}".format(err_msg, url, code, resp_data))
        return resp_data, code, headers

    # helper function - make signed requests
    def _send_signed_request(url, payload, err_msg, depth=0):
        payload64 = _b64(json.dumps(payload).encode('utf8'))
        new_nonce = _do_request(directory['newNonce'])[2]['Replay-Nonce']
        protected = {"url": url, "alg": alg, "nonce": new_nonce}
        protected.update({"jwk": jwk} if acct_headers is None else {"kid": acct_headers['Location']})
        protected64 = _b64(json.dumps(protected).encode('utf8'))
        protected_input = "{0}.{1}".format(protected64, payload64).encode('utf8')
        out = _cmd(["openssl", "dgst", "-sha256", "-sign", account_key], cmd_input=protected_input, err_msg="OpenSSL Error")
        data = json.dumps({"protected": protected64, "payload": payload64, "signature": _b64(out)})
        try:
            return _do_request(url, data=data.encode('utf8'), err_msg=err_msg, depth=depth)
        except IndexError: # retry bad nonces (they raise IndexError)
            return _send_signed_request(url, payload, err_msg, depth=(depth + 1))

    # helper function - poll until complete
    def _poll_until_not(url, pending_statuses, err_msg, timeout=90):
        deadline = time.time() + timeout
        while True:
            result, _, _ = _do_request(url, err_msg=err_msg)
            if time.time() < deadline and result['status'] in pending_statuses:
                time.sleep(2)
                continue
            return result

    # parse account key to get public key
    log.info("Parsing account key...")
    out = _cmd(["openssl", "rsa", "-in", account_key, "-noout", "-text"], err_msg="OpenSSL Error")
    pub_pattern = r"modulus:\n\s+00:([a-f0-9\:\s]+?)\npublicExponent: ([0-9]+)"
    pub_hex, pub_exp = re.search(pub_pattern, out.decode('utf8'), re.MULTILINE|re.DOTALL).groups()
    pub_exp = "{0:x}".format(int(pub_exp))
    pub_exp = "0{0}".format(pub_exp) if len(pub_exp) % 2 else pub_exp
    alg = "RS256"
    jwk = {
        "e": _b64(binascii.unhexlify(pub_exp.encode("utf-8"))),
        "kty": "RSA",
        "n": _b64(binascii.unhexlify(re.sub(r"(\s|:)", "", pub_hex).encode("utf-8"))),
    }
    accountkey_json = json.dumps(jwk, sort_keys=True, separators=(',', ':'))
    thumbprint = _b64(hashlib.sha256(accountkey_json.encode('utf8')).digest())

    # find domains
    log.info("Parsing CSR...")
    out = _cmd(["openssl", "req", "-in", csr, "-noout", "-text"], err_msg="Error loading {0}".format(csr))
    domains = set([])
    common_name = re.search(r"Subject:.*? CN\s?=\s?([^\s,;/]+)", out.decode('utf8'))
    if common_name is not None:
        domains.add(common_name.group(1))
    subject_alt_names = re.search(r"X509v3 Subject Alternative Name: \n +([^\n]+)\n", out.decode('utf8'), re.MULTILINE|re.DOTALL)
    if subject_alt_names is not None:
        for san in subject_alt_names.group(1).split(", "):
            if san.startswith("DNS:"):
                domains.add(san[4:])
    log.info("Found domains: {0}".format(", ".join(domains)))

    # get the ACME directory of urls
    log.info("Getting directory...")
    directory, _, _ = _do_request(CA, err_msg="Error getting directory")
    log.info("Directory found!")

    # create account, update contact details (if any), and set the global key identifier
    log.info("Registering account...")
    reg_payload = {"termsOfServiceAgreed": True}
    account, code, acct_headers = _send_signed_request(directory['newAccount'], reg_payload, "Error registering")
    log.info("{0}egistered: {1}".format("R" if code == 201 else "Already r", acct_headers['Location']))
    if contact is not None:
        account, _, _ = _send_signed_request(acct_headers['Location'], {"contact": contact}, "Error updating contact details")
        log.info("Updated contact details:\n{0}".format("\n".join(account['contact'])))

    # create a new order
    log.info("Creating new order...")
    order_payload = {"identifiers": [{"type": "dns", "value": d} for d in domains]}
    order, _, order_headers = _send_signed_request(directory['newOrder'], order_payload, "Error creating new order")
    log.info("Order created!")

    pending = []

    # get the authorizations that need to be completed
    for auth_url in order['authorizations']:
        authorization, _, _ = _do_request(auth_url, err_msg="Error getting challenges")
        domain = authorization['identifier']['value']
        rdomain = '*.{0}'.format(domain) if authorization.get('wildcard', False) else domain
        if authorization['status'] == 'valid':
            log.info('Existing authorization for {0} is still valid!'.format(rdomain))
            continue
        types = [c['type'] for c in authorization['challenges']]
        if 'dns-01' not in types:
            raise IndexError('Challenge dns-01 is not allowed for {0}. Permitted challenges are: {1}'.format(rdomain, ', '.join(types)))
        log.info("Verifying {0} part 1...".format(rdomain))

        # find the dns-01 challenge and write the challenge file
        challenge = [c for c in authorization['challenges'] if c['type'] == "dns-01"][0]
        token = re.sub(r"[^A-Za-z0-9_\-]", "_", challenge['token'])
        keyauthorization = "{0}.{1}".format(token, thumbprint)
        record = _b64(hashlib.sha256(keyauthorization.encode('utf8')).digest())
        log.info('_acme-challenge.%s. 60 IN TXT %s' % (domain, record))
        zone = '_acme-challenge.'+domain
        if dns_zone:
            zone = dns_zone
            if isinstance(dns_zone, int):
                zone = '.'.join(('_acme-challenge.' + domain).split('.')[dns_zone:])
        pending.append((auth_url, authorization, challenge, domain, keyauthorization, rdomain, record, token, zone))

    if pending:
        if not dns_zone_update_server:
            log.info('Press enter to continue after updating DNS server')
            six.moves.input()
        else:
            log.debug('Performing DNS Zone Updates...')
            for authz in pending:
                auth_url, authorization, challenge, domain, keyauthorization, rdomain, record, token, zone = authz
                log.debug('Updating TXT record {0} in DNS zone {1}'.format('_acme-challenge.'+domain,zone))
                update = dns.update.Update(zone, keyring=dns_zone_keyring, keyalgorithm=dns_update_algo)
                update.replace('_acme-challenge.'+domain+'.', 60, 'TXT', str(record))
                response = dns.query.tcp(update, dns_zone_update_server, timeout=10)
                if response.rcode() != 0:
                    raise Exception("DNS zone update failed, aborting, query was: {0}".format(response))

    # verify each domain
    for authz in pending:
        auth_url, authorization, challenge, domain, keyauthorization, rdomain, record, token, zone = authz

        log.info("Verifying {0} part 2...".format(rdomain))

        if not skip_check:
            # check that the DNS record is in place
            addr = set()
            for x in dns.resolver.query(dns.resolver.zone_for_name(domain), 'NS'):
                addr = addr.union(map(str, dns.resolver.query(str(x), 'A', raise_on_no_answer=False)))
                addr = addr.union(map(str, dns.resolver.query(str(x), 'AAAA', raise_on_no_answer=False)))

            if not addr:
                raise ValueError("No DNS server for {0} was found".format(domain))

            qname = '_acme-challenge.{0}'.format(domain)
            valid = []
            for x in addr:
                req = dns.message.make_query(qname, 'TXT')
                try:
                    resp = dns.query.udp(req, x, timeout=30)
                except socket.error as e:
                    log.warn('Exception contacting {0}: {1}'.format(x, e))
                except dns.exception.DNSException as e:
                    log.warn('Exception contacting {0}: {1}'.format(x, e))
                else:
                    if resp.rcode() != dns.rcode.NOERROR:
                        raise ValueError("Query for {0} returned {1} on nameserver {2}".format(qname, dns.rcode.to_text(resp.rcode()), x))
                    else:
                        answer = resp.get_rrset(resp.answer, dns.name.from_text("{0}.".format(qname.rstrip(".")), None),
                                                dns.rdataclass.IN, dns.rdatatype.TXT)
                        if answer:
                            txt = list(map(lambda x: str(x)[1:-1], answer))
                            if record not in txt:
                                raise ValueError("{0} does not contain {1} on nameserver {2}".format(qname, record, x))
                            else:
                                valid.append(x)
                        else:
                            raise ValueError("Query for {0} returned an empty answer set on nameserver {1}".format(qname, x))

            if not valid:
                raise ValueError("No DNS server for {0} was reachable".format(qname))

        # say the challenge is done
        _send_signed_request(challenge['url'], {}, "Error submitting challenges: {0}".format(rdomain))

        # skip checking challenge state because it won't change if another challenge for this authorization has completed
        authorization = _poll_until_not(auth_url, ["pending"], "Error checking authorization status for {0}".format(rdomain))
        if authorization['status'] != "valid":
            errors = [c for c in authorization['challenges'] if c['status'] not in ('valid', 'pending') and 'error' in c]
            dns_error = [c for c in errors if c['type'] == 'dns-01']

            reason = dns_error[0] if dns_error else errors[0] if errors else None
            if reason is not None:
                raise ValueError("Challenge {0} failed (status: {1}) for {2}:\n{3}".format(reason['type'], reason['status'], rdomain,
                                 pprint.pformat(reason['error'])))
            else:
                raise ValueError("Authorization failed for {0}:\n{1}".format(rdomain, pprint.pformat(authorization)))
        log.info("{0} verified!".format(domain))

    # poll the order to monitor when it's ready
    order = _poll_until_not(order_headers['Location'], ["pending"], "Error checking order status")
    if order['status'] != "ready":
        raise ValueError("Order failed: {0}".format(order))

    # finalize the order with the csr
    log.info("Signing certificate...")
    csr_der = _cmd(["openssl", "req", "-in", csr, "-outform", "DER"], err_msg="DER Export Error")
    _send_signed_request(order['finalize'], {"csr": _b64(csr_der)}, "Error finalizing order")

    # poll the order to monitor when it's done
    order = _poll_until_not(order_headers['Location'], ["ready", "processing"], "Error checking order status")
    if order['status'] != "valid":
        raise ValueError("Order failed: {0}".format(order))

    # download the certificate
    certificate_pem, _, cert_headers = _do_request(order['certificate'], err_msg="Certificate download failed")
    if cert_headers['Content-Type'] != "application/pem-certificate-chain":
        raise ValueError("Certifice received in unknown format: {0}".format(cert_headers['Content-Type']))

    # the spec recommends making sure that other types of PEM blocks don't exist in the response
    prefix = "-----BEGIN "
    suffix = "CERTIFICATE-----"
    for line in certificate_pem.splitlines():
        if line.startswith(prefix) and not line.endswith(suffix):
            raise ValueError("Unexpected PEM header in certificate: {0}".format(line))

    log.info("Certificate signed!")

    if pending:
        if not dns_zone_update_server:
            log.debug("You can now remove the _acme-challenge records from your DNS zone.")
        else:
            log.debug('Removing DNS records added for ACME challange...')
            for authz in pending:
                auth_url, authorization, challenge, domain, keyauthorization, rdomain, record, token, zone = authz
                log.debug('Removing TXT record {0} in DNS zone {1}'.format('_acme-challenge.'+domain,zone))
                update = dns.update.Update(zone, keyring=dns_zone_keyring, keyalgorithm=dns_update_algo)
                update.delete('_acme-challenge.'+domain+'.', 'TXT')
                response = dns.query.tcp(update, dns_zone_update_server, timeout=10)

    return certificate_pem

def main(argv=None):
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent("""\
            This script automates the process of getting a signed TLS certificate from Let's Encrypt using
            the ACME protocol. It will need to be run on your server and have access to your private
            account key, so PLEASE READ THROUGH IT! It's only ~300 lines, so it won't take long.

            This version has been modified from the original to use DNS challenge instead of HTTP

            Example Usage:
            python acme_tiny.py --account-key ./account.key --csr ./domain.csr > signed_chain.crt
            """)
    )
    parser.add_argument("--account-key", required=True, help="path to your Let's Encrypt account private key")
    parser.add_argument("--csr", required=True, help="path to your certificate signing request")
    parser.add_argument("--quiet", action="store_const", const=logging.ERROR, help="suppress output except for errors")
    parser.add_argument("--skip", action="store_true", help="skip checking for DNS records")
    parser.add_argument("--disable-check", dest='skip', action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--no-chain", action="store_true", help="Do not print the intermediate certificates")
    parser.add_argument("--ca", default=PROD_CA, help="certificate authority, default is Let's Encrypt Production")
    parser.add_argument("--directory-url", dest='ca', help=argparse.SUPPRESS)
    parser.add_argument("--contact", help="an optional email address to receive expiration alerts from Let's Encrypt")
    parser.add_argument("--dns-zone-update", metavar='DNS_SERVER', help="optionally automatically provision TXT record for challange on the DNS Server specified by this option using DNS zone updates")
    parser.add_argument("--dns-zone-key", nargs=3, metavar=('KEY_NAME','SECRET','ALGORITHM'), help="optional. if --dns-zone-update is used, the key name, secret and algorithm for the TSIG key which may be used to authenticate the DNS zone updates")
    parser.add_argument("--dns-zone", help="optional. if --dns-zone-update is used, specifies in which dns zone the dns zone update should be made. Per default, the challange domain (_acme-challenge.your.domain) is assumed have it's own zone. A number can be specified if a parent domain of the challange domain is the dns zone to change. Alternatively, the name of the dns zone may be explicitly specified.")

    args = parser.parse_args(argv)

    if not args.dns_zone_update and (args.dns_zone_key or args.dns_zone):
      ArgumentParser.error("--dns-zone and --dns-zone-key can only be used together with --dns-zone-update")

    dns_update_algo = None
    dns_zone_keyring = None
    if args.dns_zone_key:
      dns_zone_keyring = dns.tsigkeyring.from_text({args.dns_zone_key[0]:args.dns_zone_key[1]})
      dns_update_algo = args.dns_zone_key[2]

    if args.dns_zone and args.dns_zone.isdigit():
      args.dns_zone = int(args.dns_zone)

    LOGGER.setLevel(args.quiet or LOGGER.level)

    if args.ca.upper() in ('PRODUCTION', 'PROD', 'DEFAULT') or args.ca == PROD_CA:
        ca = PROD_CA
        LOGGER.info("Using Let's Encrypt production CA: {0}".format(ca))
    elif args.ca.upper() in ('TEST', 'STAGING', 'DEVEL') or args.ca == TEST_CA:
        ca = TEST_CA
        LOGGER.info("Using Let's Encrypt staging CA: {0}".format(ca))
    else:
        ca = args.ca
        LOGGER.info("Using other CA: {0}".format(ca))

    signed_crt = get_crt(args.account_key, args.csr, args.skip, log=LOGGER, CA=ca, contact=args.contact,
                         dns_zone_update_server=args.dns_zone_update, dns_zone_keyring=dns_zone_keyring, dns_zone=args.dns_zone,
                         dns_update_algo=dns_update_algo)

    end = "-----END CERTIFICATE-----"
    for line in signed_crt.splitlines():
        sys.stdout.write('{0}\n'.format(line))
        if args.no_chain and line == end:
            break

if __name__ == "__main__": # pragma: no cover
    main(sys.argv[1:])
