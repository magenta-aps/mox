# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/env python
import smtplib
import requests

from email.mime.text import MIMEText
from settings import MOX_ADVIS_QUEUE
from settings import OIOREST_SERVER
from settings import FROM_EMAIL
from settings import ADVIS_SUBJECT_PREFIX
from settings import MOX_ADVIS_LOG_FILE
from settings import SAML_MOX_ENTITY_ID
from settings import SAML_IDP_ENTITY_ID
from structlog import get_logger

# TODO:
# In order to refactor the SAML related import(s)
# We must first extract the Saml2_Assertion class
# into its own library
from oio_rest.auth.saml2 import Saml2_Assertion

from mox_agent import MOXAgent, unpack_saml_token, get_idp_cert

logger = get_logger()

def get_destination_emails(uuids, headers):
    """Get email addresses from Organisation using a list of UUIDs."""
    destination_emails = []
    bruger_url = "{0}/organisation/bruger".format(OIOREST_SERVER)
    for uuid in uuids:
        request_url = "{0}?uuid={1}".format(bruger_url, uuid)

        response = requests.get(request_url, headers=headers)
        result = response.json()
        if response.status_code != 200:
            logger.error("Failed to connect to API: %s", result=result)
            continue

        if len(result['results']) == 0:
            logger.error("Bruger for UUID %s not found.", uuid=uuid)
            continue
        try:
            addresses = result[
                'results'][0][0]['registreringer'][0]['relationer']['adresser']
            mail_urn = None
        except (KeyError, IndexError):
            logger.error("No addresses found for Bruger %s.", uuid=uuid)
            continue

        for a in addresses:
            # No need to consider Virkning periods as these are always NOW
            if a.get('objekttype', '') == 'email':
                mail_urn = a['urn']
                break

        if mail_urn:
            try:
                destination_email = mail_urn[mail_urn.rfind(':')+1:]
            except:
                logger.error("Error in URN format: %s", mail_urn=mail_urn)
                raise
            destination_emails.append(destination_email)
        else:
            logger.warning("No email address configured for Bruger %s", uuid=uuid)
            # Do nothing
            pass
    return destination_emails


class MOXAdvis(MOXAgent):
    """Support for the MOX Advis use case."""

    def __init__(self):
        # Get rid of certain warnings
        requests.packages.urllib3.disable_warnings()

    queue = MOX_ADVIS_QUEUE
    do_persist = True

    def callback(self, ch, method, properties, body):
        """Extract UUID and SAML token - send body as email to user."""
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
            logger.error("No valid authentication, can't proceed: %s", message=e.message)
            return

        attributes = assertion.get_attributes()

        # Get recipients, subject, default from address
        uuids = properties.headers.get('query', None)
        if isinstance(uuids, basestring):
            uuids = [uuids]
        subject = properties.headers.get('subject', '')
        from_address = FROM_EMAIL
        # Get From: email from SAML assertion.
        # TODO: It should be possible to override this in configuration.
        from_email = attributes.get(
            'http://wso2.org/claims/emailaddress', [None]
        )[0]
        if from_email:
            from_address = from_email
        if not uuids:
            # Extract uuid from SAML token
            uuid = attributes['http://wso2.org/claims/url'][0]
            uuids = [uuid]

        # UUIDs OK, either from query header or from SAML token.
        # Now retrieve email addresses from Organisation.
        headers = {"Authorization": gzip_token}
        destination_emails = get_destination_emails(uuids, headers)
        # Ready to send mail.
        try:
            smtp = smtplib.SMTP('localhost')
        except Exception as e:
            logger.critical('Unable to connect to mail server: %s', message=e.message)
            return

        for email in destination_emails:
            msg = MIMEText(body)
            msg['Subject'] = "{0} {1}".format(ADVIS_SUBJECT_PREFIX, subject)
            msg['From'] = from_address
            msg['To'] = email
            smtp.sendmail(FROM_EMAIL, email, msg.as_string())


if __name__ == '__main__':
    agent = MOXAdvis()
    agent.run()
