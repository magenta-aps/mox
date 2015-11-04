#!/usr/bin/env python
import zlib
import base64

import pika
import requests
from settings import AMQP_SERVER, MOX_ADVIS_QUEUE, OIOREST_SERVER

from oio_rest.settings import SAML_MOX_ENTITY_ID, SAML_IDP_ENTITY_ID
from oio_rest.auth.saml2 import Saml2_Assertion

IDP_CERTIFICATE = 'test_auth_data/idp-certificate.pem'

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host=AMQP_SERVER)
)
channel = connection.channel()

channel.queue_declare(queue=MOX_ADVIS_QUEUE, durable=True)

# Get rid of certain warnings
from requests.packages import urllib3
urllib3.disable_warnings()

print ' [*] Waiting for messages. To exit press CTRL+C'


def unpack_saml_token(token):
    """Retrieve the SAML XML from a gzipped auth header."""
    data = token.split(' ')[1]
    data = base64.b64decode(data)

    token = zlib.decompress(data, 15+16)

    return token


def get_idp_cert():
    try:
        with open(IDP_CERTIFICATE) as file:
            return file.read()
    except Exception:
        raise


def callback(ch, method, properties, body):
    """Extract UUID and SAML token - send body as email to user."""
    gzip_token = properties.headers.get(
        'authorization', None
    ) if properties.headers else None
    saml_token = unpack_saml_token(gzip_token) if gzip_token else None
    # TODO: If no SAML token, we can't proceed!
    # Please log properly.
    if not saml_token:
        print "ERROR: No authentication present!"
        return
    uuid = properties.headers.get('uuid', None)

    if uuid:
        # TODO: Contact Organisation service to get email address for user
        print uuid
    else:
        # TODO: Extract uuid from SAML token
        assertion = Saml2_Assertion(saml_token, SAML_MOX_ENTITY_ID,
                                    SAML_IDP_ENTITY_ID, get_idp_cert())
        try:
            assertion.check_validity()
        except Exception as e:
            print "No valid authentication, can't proceed!"
            print e.message
            return
    attributes = assertion.get_attributes()
    uuid = attributes['http://wso2.org/claims/url'][0]

    # UUID OK, now retrieve email address from Organisation.
    bruger_url = "{0}/organisation/bruger".format(OIOREST_SERVER)
    request_url = "{0}?uuid={1}".format(bruger_url, uuid)
    headers = {"Authorization": gzip_token}

    print gzip_token
    resp = requests.get(request_url, headers=headers)
    result = resp.json()
    print result


channel.basic_qos(prefetch_count=1)
channel.basic_consume(callback, queue=MOX_ADVIS_QUEUE, no_ack=True)

channel.start_consuming()
