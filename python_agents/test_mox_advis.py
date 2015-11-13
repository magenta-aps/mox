#!/usr/bin/env python
import sys

import pika
import requests

from settings import AMQP_SERVER, MOX_ADVIS_QUEUE
from settings import OIOREST_SERVER


def get_saml_token():
    """Obtain SAML token in order to test MOX agent."""
    userdata = {'username': 'agger', 'password': 'agger'}
    url = "{0}/{1}".format(OIOREST_SERVER, "get-token")
    # Just for now, later update to a newer Python version.
    from requests.packages import urllib3
    urllib3.disable_warnings()
    resp = requests.post(url, userdata)

    return resp.text


# SAML token for authentication against OIO REST services.
saml_token = get_saml_token()
uuid = 'beeef82b-c51c-4df7-b49f-e9d35b99c4af'
uuid_not_working = '10100ef4-0ac4-4bb1-aaee-3343fe017103'
uuid_doesnt_exist = '10100ef4-0ac4-4bb1-aaee-3343f6666666'
uuid_no_address = '431607f7-e764-4b1a-917f-2c08a2df0e59'

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=AMQP_SERVER))
channel = connection.channel()

channel.queue_declare(queue=MOX_ADVIS_QUEUE, durable=True)

message = ' '.join(sys.argv[1:]) or "Hello World!"
subject = 'MOX Advis test message'
channel.basic_publish(exchange='',
                      routing_key=MOX_ADVIS_QUEUE,
                      body=message,
                      properties=pika.BasicProperties(
                          content_type='text/plain',
                          delivery_mode=2,
                          headers={'authorization': saml_token,
                                   'query': [uuid,
                                             uuid_not_working,
                                             uuid_doesnt_exist,
                                             uuid_no_address],
                                   'subject': subject, }
                      ))
print " [x] Sent '%s'" % message
connection.close()
