from datetime import datetime
from settings import BASE_URL

import pika
import requests
import json

from settings import LOG_AMQP_SERVER, LOG_QUEUE, LOG_IGNORED_SERVICES


def log_service_call(service_name, class_name, time,
                     operation, return_code, msg, note, user_uuid, role,
                     object_uuid):
    """Log a call to a LoRa service."""

    if service_name in LOG_IGNORED_SERVICES:
        "Don't log the log service."
        return

    # Virkning for all virkning periods.
    virkning = {
        "from": str(time),
        "to": "infinity",
        "aktoerref": user_uuid,
        "aktoertypekode": "Bruger",
        "notetekst": ""
    }
    logevent_dict = {
        "note": BASE_URL,
        "attributter": {
            "loghaendelseegenskaber": [
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
                    "gyldighed": "Aktiv",
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
                    "urn": role,
                    "virkning": virkning
                }
            ]
        }
    }

    # TODO: Get auth token if auth enabled
    authorization = ''
    # Send AMQP message to LOG_SERVICE_URL

    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=LOG_AMQP_SERVER
    ))
    channel = connection.channel()
    channel.queue_declare(queue=LOG_QUEUE)
    message = json.dumps(logevent_dict)

    channel.basic_publish(
        exchange='',
        routing_key=LOG_QUEUE,
        body=message,
        properties=pika.BasicProperties(
            content_type='application/json',
            delivery_mode=2,
            headers={
                'beskedversion': "1",
                'beskedID': object_uuid,
                'objekttype': 'LogHaendelse',
                'operation': 'create',
            }
        ))
