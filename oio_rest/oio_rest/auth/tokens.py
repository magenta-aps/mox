import base64
import datetime
import os
import sys
import urllib2
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

def get_token(username, passwd, pack=True, pretty_print=False):
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

    headers = {
        'Content-Type': 'application/soap+xml; charset=utf-8',
    }
    req = urllib2.Request(idp_url, xml, headers)

    try:
        urlfp = urllib2.urlopen(req)
    except urllib2.HTTPError as e:
        # do something?
        ct = e.info().get('Content-Type', '').split(';')[0]

        if e.getcode() == 500 and ct == 'application/soap+xml':
            doc = etree.parse(e)

            try:
                raise Exception(' '.join(doc.getroot().itertext('{*}Text')))
            finally:
                e.close()

        raise

    try:
        doc = etree.parse(urlfp)
    finally:
        urlfp.close()

    tokens = doc.findall('.//{*}RequestedSecurityToken/{*}Assertion')

    if len(tokens) == 0:
        raise KeyError('no tokens found - is the endpoint correct?')
    if len(tokens) > 1:
        raise KeyError('too many tokens found')

    assert len(tokens) == 1

    token = etree.tostring(tokens[0], pretty_print=pretty_print)

    if pack:
        return 'saml-gzipped ' + base64.standard_b64encode(_gzipstring(token))
    else:
        return token


def main(*args):
    import argparse
    import getpass
    import sys

    parser = argparse.ArgumentParser(
        description='request a SAML token'
    )

    parser.add_argument('user')

    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-f', '--full', action='store_true')
    parser.add_argument('-p', '--password')

    options = parser.parse_args()

    password = options.password or getpass.getpass('Password: ')

    token = get_token(options.user, password, options.full, options.verbose)

    sys.stdout.write(token)

    return 0


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

__all__ = ('get_token')
