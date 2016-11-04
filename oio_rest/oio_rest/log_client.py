from datetime import datetime
from settings import BASE_URL

import pika
import requests
import json

# This is the URL of the RabbitMQ server to which we send the log messages.


def log_service_call(log_destination, service_name, class_name, time,
                     operation, return_code, msg, note, user_uuid, role_uuid, object_uuid):
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
        "attributter": {
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
    pass  # Start with no authorization.    # Send AMQP message to LOG_SERVICE_URL

    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=LOG_AMQP_SERVER
    ))
    channel = connection.channel()
    channel.queue_declare(queue=LOG_QUEUE, durable=True)

    message = json.dumps(logevent_dict)
    subject = "Log-besked"


    channel.basic_publish(
        exchange='',
        routing_key=LOG_QUEUE,
        body=message,
        properties=pika.BasicProperties(
            content_type='application/json',
            delivery_mode=2,
            headers={  # 'autorisation': saml_token,
                     'operation': 'create',
                     'objekttype': 'LogHaendelse',
                    }
        ))
