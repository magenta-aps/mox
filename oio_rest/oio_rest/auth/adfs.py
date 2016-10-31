import base64
import getpass
import gzip
import json
import os
import string
import sys
import urllib2
import zlib

from cStringIO import StringIO
from xml.dom import minidom
import jinja2

SOAP_NS = 'http://www.w3.org/2003/05/soap-envelope'
TRUST_NS = 'http://docs.oasis-open.org/ws-sx/ws-trust/200512'

curdir = os.path.dirname(os.path.realpath(__file__))
jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader(
    os.path.join(curdir, '..', 'templates', 'xml')
))


def _gzipstring(s):
    compressor = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION,
                                  zlib.DEFLATED, 16 + zlib.MAX_WBITS)

    return compressor.compress(s) + compressor.flush()

    fp = StringIO()
    with gzip.GzipFile(fileobj=fp, mode='wb') as gzfp:
        gzfp.write(s)
    return fp.getvalue()


def get_token(username, passwd, idp_url, endpoint, pretty_print=False):
    '''Request a SAML authentication token from the given host and endpoint.

    Windows Server typically returns a 500 Internal Server Error on
    authentication errors; this function simply raises a
    httplib.HTTPError in these cases. In other cases, it returns a
    KeyError.

    '''
    t = jinja_env.get_template('adfs-soap-request.xml')
    xml = t.render(
        username=username,
        password=passwd,
        endpoint=endpoint,
    )

    headers = {
        'Content-Type': 'application/soap+xml; charset=utf-8',
    }
    req = urllib2.Request(idp_url, xml, headers)

    try:
        urlfp = urllib2.urlopen(req)
    except urllib2.HTTPError as e:
        # do something?
        ct = e.info()['Content-Type'].split(';')[0]

        if e.getcode() == 500 and ct == 'application/soap+xml':
            try:
                doc = minidom.parse(e)
            finally:
                e.close()
            reason = doc.getElementsByTagNameNS(SOAP_NS, 'Reason')
            # the reason rarely makes sense

        raise

    try:
        doc = minidom.parse(urlfp)
    finally:
        urlfp.close()

    tokens = doc.getElementsByTagNameNS(TRUST_NS, 'RequestedSecurityToken')
    if len(tokens) == 0:
        raise KeyError('no tokens found - is the endpoint correct?')
    if len(tokens) > 1:
        raise KeyError('too many tokens found')

    assert len(tokens[0].childNodes) == 1

    token = tokens[0].firstChild

    if pretty_print:
        return token.toprettyxml(indent=' ' * 2)
    else:
        return token.toxml()


def pack_token(token):
    '''Format an XML token string as saml-gzipped.'''
    return 'saml-gzipped ' + base64.standard_b64encode(_gzipstring(token))


def get_packed_token(*args, **kwargs):
    return pack_token(get_token(*args, **kwargs))


if __name__ == '__main__':
    # for testing
    import settings
    import argparse

    parser = argparse.ArgumentParser(
        description='request a SAML token from a Windows server'
    )

    parser.add_argument('user')

    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-f', '--full', action='store_true')

    options = parser.parse_args()
    password = getpass.getpass('Password: ')

    token = get_token(options.user, password,
                      settings.SAML_IDP_URL, settings.SAML_MOX_ENTITY_ID,
                      options.verbose)

    if options.full:
        token = pack_token(token)

    sys.stdout.write(token)

__all__ = ('auth', 'get_token')
