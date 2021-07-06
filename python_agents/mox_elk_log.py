# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!%PYTHON%
import json
import pika

import requests

from settings import MOX_LOG_EXCHANGE, MOX_OBJECT_EXCHANGE, DO_LOG_TO_AMQP
from settings import MOX_ELK_LOG_FILE, IS_LOG_AUTHENTICATION_ENABLED

from settings import SAML_MOX_ENTITY_ID
from settings import SAML_IDP_ENTITY_ID

# TODO:
# In order to refactor the SAML related import(s)
# We must first extract the Saml2_Assertion class
# into its own library
from oio_rest.auth.saml2 import Saml2_Assertion

from settings import MOX_LOGSTASH_URI
from settings import MOX_LOGSTASH_USER
from settings import MOX_LOGSTASH_PASS

from structlog import get_logger

from mox_agent import MOXAgent, unpack_saml_token, get_idp_cert

logger = get_logger()

class MOXELKLog(MOXAgent):
    """Support for the MOX Advis use case."""

    def __init__(self):
        # Get rid of certain warnings
        requests.packages.urllib3.disable_warnings()

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
                logger.error("ERROR: No authentication present!")
                return
            # Validate SAML token
            assertion = Saml2_Assertion(saml_token, SAML_MOX_ENTITY_ID,
                                        SAML_IDP_ENTITY_ID, get_idp_cert())
            try:
                assertion.check_validity()
            except Exception as e:
                logger.error(
                    "No valid authentication, can't proceed: %s", message=e.message
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
            logger.info("Posting to logstash ...")
            data = json.loads(body)  # noqa
            r = requests.post(MOX_LOGSTASH_URI, body, auth=(MOX_LOGSTASH_USER,
                                                            MOX_LOGSTASH_PASS))
            logger.info("Done: %s", request=r)


if __name__ == '__main__':
    agent = MOXELKLog()
    agent.run()
