from datetime import datetime
from settings import BASE_URL

import pika
import requests
import json

from settings import LOG_AMQP_SERVER, LOG_QUEUE, LOG_IGNORED_SERVICES


def log_service_call(service_name, class_name, time,
                     operation, return_code, msg, note, user_uuid, role_uuid,
                     object_uuid):
    """Log a call to a LoRa service."""

    if service_name in LOG_IGNORED_SERVICES:
        "Don't log the log service."
        return

    # Virkning for all virkning periods.
    virkning = {
        "from": str(time),
        "to": "infinity",
        "aktoerref": "TODO",
        "aktoertypekode": "Bruger",
        "notetekst": ""
    }
    logevent_dict = {
        "note": BASE_URL,
        "attributter": {
            "loghaendelsesegenskaber": [
                {
                    "service": service_name,
                    "klasse": class_name,
                    "tidspunkt": str(time),
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
                }
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
    pass  # Start with no authorization.
    # Send AMQP message to LOG_SERVICE_URL

    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=LOG_AMQP_SERVER
    ))
    channel = connection.channel()
    channel.queue_declare(queue=LOG_QUEUE, durable=True)

    message = json.dumps(logevent_dict)
    print "LOG-BESKED:", message
    subject = "Log-besked"

    channel.basic_publish(
        exchange='',
        routing_key=LOG_QUEUE,
        body=message,
        properties=pika.BasicProperties(
            content_type='application/json',
            delivery_mode=2,
            headers={
                'operation': 'create',
                'objekttype': 'LogHaendelse',
            }
        ))
