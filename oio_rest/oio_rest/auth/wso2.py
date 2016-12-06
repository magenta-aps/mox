import datetime
import os
import urllib2

from xml.dom import minidom
import jinja2
import pytz

from . import util

SOAP_NS = 'http://www.w3.org/2003/05/soap-envelope'
TRUST_NS = 'http://schemas.xmlsoap.org/ws/2005/02/trust'

curdir = os.path.dirname(os.path.realpath(__file__))
jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader(
    os.path.join(curdir, '..', 'templates', 'xml')
))


def get_token(username, passwd, idp_url, endpoint, pretty_print):
    '''Request a SAML authentication token from the given host and endpoint.

    Windows Server typically returns a 500 Internal Server Error on
    authentication errors; this function simply raises a
    httplib.HTTPError in these cases. In other cases, it returns a
    KeyError.

    '''

    created = datetime.datetime.now(pytz.utc)
    expires = created + datetime.timedelta(hours=1)

    t = jinja_env.get_template('wso2-soap-request.xml')
    xml = t.render(
        username=username,
        password=passwd,
        endpoint=endpoint,
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
        ct = e.info()['Content-Type'].split(';')[0]

        if e.getcode() == 500 and ct == 'application/soap+xml':
            # the reason rarely makes sense, but report it nonetheless
            try:
                reason = util.get_reason(minidom.parse(e))
            finally:
                e.close()
            raise Exception(reason)

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

__all__ = ('get_token')
