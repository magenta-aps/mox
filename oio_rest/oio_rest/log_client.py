# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import pika
import json

from . import settings


def log_service_call(service_name, class_name, time,
                     operation, return_code, msg, note, user_uuid, role,
                     object_uuid):
    """Log a call to a LoRa service."""

    if (
        service_name in settings.LOG_IGNORED_SERVICES or
        not settings.LOG_AMQP_SERVER
    ):
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
        "note": settings.BASE_URL,
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
                    "urn": role,
                    "virkning": virkning
                }
            ]
        }
    }

    # TODO: Get auth token if auth enabled

    if settings.AUDIT_LOG_FILE:
        with open(settings.AUDIT_LOG_FILE, 'at') as fp:
            json.dump(logevent_dict, fp, indent=2)
            fp.write('\n')
            fp.flush()

    # Send AMQP message to LOG_SERVICE_URL

    if settings.LOG_AMQP_SERVER:
        connection = pika.BlockingConnection(pika.ConnectionParameters(
            host=settings.LOG_AMQP_SERVER
        ))
        channel = connection.channel()
        channel.queue_declare(queue=settings.MOX_LOG_QUEUE)
        channel.exchange_declare(exchange=settings.MOX_LOG_EXCHANGE,
                                 exchange_type='fanout')
        channel.queue_bind(settings.MOX_LOG_QUEUE,
                           exchange=settings.MOX_LOG_EXCHANGE)

        message = json.dumps(logevent_dict)
        # print "Log exchange", LOG_EXCHANGE

        channel.basic_publish(
            exchange=settings.MOX_LOG_EXCHANGE,
            routing_key='',
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
