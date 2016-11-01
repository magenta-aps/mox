from datetime import datetime
from settings import BASE_URL
# This is the URL of the RabbitMQ server to which we send the log messages.

LOG_SERVICE_URL = 'http://127.0.0.15672'

def log_service_call(service_name, class_name, time, operation, return_code,
                     msg, note, user_uuid, role_uuid, object_uuid):
    """Log a call to a LoRa service."""

    # Virkning for all virkning periods.
    virkning = {
        "from": time,
        "to": "infinity",
        "aktoerref": "TODO",
        "aktoertypekode": "Bruger",
        "notetekst": ""
    }
    logevent_dict = {
        "note": BASE_URL, 
        "attributter" {
            "loghaendelsesegenskaber": [
                {
                    "service": service_name, 
                    "klasse": class_name,
                    "tidspunkt": time, 
                    "operation": operation,
                    "returkode": return_code,
                    "returtekst": msg,
                    "note": note, 
                    "virkning": virkning
                }
            ]
        },
        "tilstande": {
            "loghaendelsegyldighed": [
                {
                    "gyldighed": "Ikke rettet",
                    "virkning": virkning
                }
            ]
        },
        "relationer": {
            "objekt": [
                {
                    "uuid": object_uuid,
                    "virkning": virkning
                } if object_uuid
            ],
            "bruger": [
                {
                    "uuid": user_uuid,
                    "virkning": virkning
                }
            ],
            "brugerrolle": [
                {
                    "uuid": role_uuid,
                    "virkning": virkning
                }
            ]
        }
    }

    # Get auth token if auth enabled
    # Send AMQP message to LOG_SERVICE_URL
½
