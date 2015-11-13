#!/usr/bin/env python
import zlib
import base64
import smtplib
import logging


import requests

from email.mime.text import MIMEText
from settings import MOX_ADVIS_QUEUE, OIOREST_SERVER, FROM_EMAIL
from settings import ADVIS_SUBJECT_PREFIX, SAML_IDP_CERTIFICATE
from settings import MOX_ADVIS_LOG_FILE

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


def get_destination_emails(uuids, headers):
    """Get email addresses from Organisation using a list of UUIDs."""
    destination_emails = []
    bruger_url = "{0}/organisation/bruger".format(OIOREST_SERVER)
    for uuid in uuids:
        request_url = "{0}?uuid={1}".format(bruger_url, uuid)

        response = requests.get(request_url, headers=headers)
        result = response.json()
        if response.status_code != 200:
            logging.error("Failed to connect to API: {0}".format(result))
            continue

        if len(result['results']) == 0:
            logging.error("Bruger for UUID {0} not found.".format(uuid))
            continue
        try:
            addresses = result[
                'results'][0][0]['registreringer'][0]['relationer']['adresser']
            mail_urn = None
        except (KeyError, IndexError):
            logging.error("No addresses found for Bruger {0}.".format(uuid))
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
                logging.error("Error in URN format: {0}".format(mail_urn))
                raise
            destination_emails.append(destination_email)
        else:
            logging.warning(
                "No email address configured for Bruger {0}".format(uuid)
            )
            # Do nothing
            pass
    return destination_emails


class MOXAdvis(MOXAgent):
    """Support for the MOX Advis use case."""

    def __init__(self):
        # Get rid of certain warnings
        requests.packages.urllib3.disable_warnings()
        # Set up logging
        logging.basicConfig(filename=MOX_ADVIS_LOG_FILE, level=logging.DEBUG)

    queue = MOX_ADVIS_QUEUE
    do_persist = True

    def callback(self, ch, method, properties, body):
        """Extract UUID and SAML token - send body as email to user."""
        gzip_token = properties.headers.get(
            'authorization', None
        ) if properties.headers else None
        saml_token = unpack_saml_token(gzip_token) if gzip_token else None
        # TODO: If no SAML token, we can't proceed!
        # Please log properly.
        if not saml_token:
            logging.error("ERROR: No authentication present!")
            return
        uuids = properties.headers.get('query', None)
        subject = properties.headers.get('subject', '')
        from_address = FROM_EMAIL
        # Validate SAML token
        assertion = Saml2_Assertion(saml_token, SAML_MOX_ENTITY_ID,
                                    SAML_IDP_ENTITY_ID, get_idp_cert())
        try:
            assertion.check_validity()
        except Exception as e:
            logging.error(
                "No valid authentication, can't proceed: {0}".format(e.message)
            )
            return

        attributes = assertion.get_attributes()
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
        smtp = smtplib.SMTP('localhost')
        for email in destination_emails:
            msg = MIMEText(body)
            msg['Subject'] = "{0} {1}".format(ADVIS_SUBJECT_PREFIX, subject)
            msg['From'] = from_address
            msg['To'] = email
            smtp.sendmail(FROM_EMAIL, email, msg.as_string())


if __name__ == '__main__':
    agent = MOXAdvis()
    agent.run()
