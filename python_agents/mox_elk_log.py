#!/usr/bin/env /home/mox/mox/python_agents/python-env/bin/python
import zlib
import base64
import logging


import requests

from settings import MOX_LOG_EXCHANGE
from settings import SAML_IDP_CERTIFICATE
from settings import MOX_ELK_LOG_FILE, IS_LOG_AUTHENTICATION_ENABLED

from oio_rest.settings import SAML_MOX_ENTITY_ID, SAML_IDP_ENTITY_ID
from oio_rest.auth.saml2 import Saml2_Assertion

from mox_agent import MOXAgent


def unpack_saml_token(token):
    """Retrieve the SAML XML from a gzipped auth header."""
    data = token.split(' ')[1]
    data = base64.b64decode(data)

    token = zlib.decompress(data, 15+16)

    return token


def get_idp_cert():
    try:
        with open(SAML_IDP_CERTIFICATE) as file:
            return file.read()
    except Exception:
        raise


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
        print body


if __name__ == '__main__':
    agent = MOXELKLog()
    agent.run()
