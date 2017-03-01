import base64
import datetime
import os
import sys
import requests
import zlib

from lxml import etree
import jinja2
import pytz

from .. import settings

curdir = os.path.dirname(os.path.realpath(__file__))
jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader(
    os.path.join(curdir, '..', 'templates', 'xml')
))

IDP_TEMPLATES = {
    'adfs': 'adfs-soap-request.xml',
    'wso2': 'wso2-soap-request.xml',
}


def _gzipstring(s):
    compressor = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION,
                                  zlib.DEFLATED, 16 + zlib.MAX_WBITS)

    return compressor.compress(s) + compressor.flush()


def get_token(username, passwd, pretty_print=False, insecure=False):
    '''Request a SAML authentication token from the given host and endpoint.

    Windows Server typically returns a 500 Internal Server Error on
    authentication errors; this function simply raises a
    httplib.HTTPError in these cases. In other cases, it returns a
    KeyError. WSO2 tends to yield more meaningful errors.

    '''

    idp_type = getattr(settings, 'SAML_IDP_TYPE', 'wso2')
    idp_url = settings.SAML_IDP_URL
    endpoint = settings.SAML_MOX_ENTITY_ID

    created = datetime.datetime.now(pytz.utc)
    expires = created + datetime.timedelta(hours=1)

    t = jinja_env.get_template(IDP_TEMPLATES[idp_type])
    xml = t.render(
        username=username,
        password=passwd,
        endpoint=endpoint,
        idp_url=idp_url,
        created=created.isoformat(),
        expires=expires.isoformat(),
    )

    resp = requests.post(idp_url, data=xml, verify=not insecure, headers={
        'Content-Type': 'application/soap+xml; charset=utf-8',
    }, )

    if not resp.ok:
        # do something?
        ct = resp.headers.get('Content-Type', '').split(';')[0]

        if resp.status_code == 500 and ct == 'application/soap+xml':
            doc = etree.fromstring(resp.content)

            raise Exception(' '.join(doc.itertext('{*}Text')))

        resp.raise_for_status()

    doc = etree.fromstring(resp.content)

    if doc.find('./{*}Body/{*}Fault') is not None:
        raise Exception(' '.join(doc.itertext('{*}Text')))

    tokens = doc.findall('.//{*}RequestedSecurityToken/{*}Assertion')

    if len(tokens) == 0:
        raise KeyError('no tokens found - is the endpoint correct?')
    if len(tokens) > 1:
        raise KeyError('too many tokens found')

    assert len(tokens) == 1

    if pretty_print:
        return etree.tostring(tokens[0], pretty_print=pretty_print)
    else:
        text = \
            base64.standard_b64encode(_gzipstring(etree.tostring(tokens[0])))

        return 'saml-gzipped ' + text


def main(*args):
    import argparse
    import getpass
    import sys

    parser = argparse.ArgumentParser(
        description='request a SAML token'
    )

    parser.add_argument('-u', '--user',
                        help="account user name")
    parser.add_argument('-p', '--password',
                        help="account password")
    parser.add_argument('-r', '--raw', action='store_true',
                        help="don't pack and wrap the token")
    parser.add_argument('--insecure', action='store_true',
                        help="disable SSL/TLS security checks")
    parser.add_argument('--cert-only', action='store_true',
                        help="output embedded certificates in PEM form")

    # compatibility argument -- we don't print out anything
    parser.add_argument('-s', '--silent', action='store_true',
                        help=argparse.SUPPRESS, default=argparse.SUPPRESS)

    options = parser.parse_args()

    def my_input(prompt):
        sys.stderr.write(prompt)
        return raw_input()

    username = options.user or my_input('User: ')
    password = options.password or getpass.getpass('Password: ')

    if options.insecure:
        from requests.packages import urllib3
        urllib3.disable_warnings()

    try:
        token = get_token(username, password,
                          options.raw or options.cert_only,
                          options.insecure)
    except requests.exceptions.SSLError as e:
        msg = ('SSL request failed; you probably need to install the '
               'appropriate certificate authority, or use the correct host '
               'name')
        print >> sys.stderr, msg, e
        return 1

    if not options.cert_only:
        sys.stdout.write(token)

    else:
        from lxml import etree
        import ssl

        for el in etree.fromstring(token).findall('.//{*}X509Certificate'):
            data = base64.standard_b64decode(el.text)

            sys.stdout.write(ssl.DER_cert_to_PEM_cert(data))

    return 0


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

__all__ = ('get_token')
