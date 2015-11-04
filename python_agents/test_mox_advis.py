#!/usr/bin/env python
import sys

import pika
import requests

from settings import AMQP_SERVER, MOX_ADVIS_QUEUE
from settings import OIOREST_SERVER


def get_saml_token():
    """Obtain SAML token in order to test MOX agent."""
    userdata = {'username': 'admin', 'password': 'admin'}
    url = "{0}/{1}".format(OIOREST_SERVER, "get-token")
    # Just for now, later update to a newer Python version.
    from requests.packages import urllib3
    urllib3.disable_warnings()
    resp = requests.post(url, userdata)

    return resp.text


# SAML token for authentication against OIO REST services.
saml_token = get_saml_token()
uuid = '23c7e72e-2b99-495d-95a2-08b049b364bb'
print saml_token

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=AMQP_SERVER))
channel = connection.channel()

channel.queue_declare(queue=MOX_ADVIS_QUEUE, durable=True)

message = ' '.join(sys.argv[1:]) or "Hello World!"
channel.basic_publish(exchange='',
                      routing_key=MOX_ADVIS_QUEUE,
                      body=message,
                      properties=pika.BasicProperties(
                          content_type='text/plain',
                          delivery_mode=2,
                          headers={'authorization': saml_token,
                                   'uuid': uuid}
                      ))
print " [x] Sent '%s'" % message
connection.close()
