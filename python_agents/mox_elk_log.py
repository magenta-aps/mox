#!%PYTHON%
import logging
import json
import pika

import requests

from settings import MOX_LOG_EXCHANGE, MOX_OBJECT_EXCHANGE, DO_LOG_TO_AMQP
from settings import MOX_ELK_LOG_FILE, IS_LOG_AUTHENTICATION_ENABLED

from oio_rest.settings import SAML_MOX_ENTITY_ID, SAML_IDP_ENTITY_ID
from oio_rest.auth.saml2 import Saml2_Assertion

from mox_agent import MOXAgent, unpack_saml_token, get_idp_cert

# Logstash configuration
logstash_url = 'http://139.162.183.253:42998'
logstash_user = 'hunter2'
logstash_password = 'fghTJ425245ADCFVd'


class MOXELKLog(MOXAgent):
    """Support for the MOX Advis use case."""

    def __init__(self):
        # Get rid of certain warnings
        requests.packages.urllib3.disable_warnings()
        # Set up logging
        logging.basicConfig(
            filename=MOX_ELK_LOG_FILE,
            level=logging.DEBUG,
            format='%(asctime)s %(levelname)s %(message)s'
        )

    queue = ''
    exchange = MOX_LOG_EXCHANGE
    do_persist = False

    def callback(self, ch, method, properties, body):
        """Extract UUID and SAML token - send body as email to user."""
        if IS_LOG_AUTHENTICATION_ENABLED:
            # Authenticate
            gzip_token = properties.headers.get(
                'autorisation', None
            ) if properties.headers else None
            saml_token = unpack_saml_token(gzip_token) if gzip_token else None
            # TODO: If no SAML token, we can't proceed!
            # Please log properly.
            if not saml_token:
                logging.error("ERROR: No authentication present!")
                return
            # Validate SAML token
            assertion = Saml2_Assertion(saml_token, SAML_MOX_ENTITY_ID,
                                        SAML_IDP_ENTITY_ID, get_idp_cert())
            try:
                assertion.check_validity()
            except Exception as e:
                logging.error(
                    "No valid authentication, can't proceed: {0}".format(
                        e.message
                    )
                )
                return
        if DO_LOG_TO_AMQP:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host='localhost')
            )
            channel = connection.channel()
            channel.basic_publish(exchange=MOX_OBJECT_EXCHANGE,
                                  routing_key='',
                                  properties=properties,
                                  body=body)
        else:
            print "Posting to logstash ..."
            data = json.loads(body)  # noqa
            r = requests.post(logstash_url, body, auth=(logstash_user,
                                                        logstash_password))
            print "Done: ", r


if __name__ == '__main__':
    agent = MOXELKLog()
    agent.run()
