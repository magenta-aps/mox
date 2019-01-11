# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


""" Simple class to relay messages from PostgreSQL notifications
into an AMQP-queue """
import select
import json
import pika
import psycopg2
from os import getenv


def AMQPNotifier(database, user, password, host):
    """ Main notification thread.
    :param database: The PostgreSQL database
    :param user:  The PostgreSQL user
    :param password: The PostgreSQL password
    :param host:  The PostgreSQL hostname
    """
    pg_conn = psycopg2.connect(database=database, user=user,
                               password=password, host=host)
    pg_cursor = pg_conn.cursor()
    pika_params = pika.ConnectionParameters('localhost')
    pika_connection = pika.BlockingConnection(pika_params)
    amqp = pika_connection.channel()
    amqp.queue_declare(queue='mox.notifications')

    pg_cursor.execute("LISTEN mox_notifications;")
    pg_conn.poll()
    pg_conn.commit()
    while True:
        if select.select([pg_conn], [], [], 60) == ([], [], []):
            pass
        else:
            pg_conn.poll()
            pg_conn.commit()
            while pg_conn.notifies:
                notify = pg_conn.notifies.pop(0)
                payload_dict = json.loads(notify.payload)

                table = payload_dict['table']
                objekttype = table[0:table.find('registrering')-1]
                objektID = payload_dict['data'][objekttype + '_id']
                registrering = payload_dict['data']['registrering']
                livscykluskode = registrering['livscykluskode']

                amqp_payload = {'beskedtype': 'Notification',
                                'objektID': objektID,
                                'objekttype': objekttype,
                                'livscykluskode': livscykluskode}

                amqp.basic_publish(exchange='',
                                   routing_key='mox.notifications',
                                   body=json.dumps(amqp_payload))

if __name__ == '__main__':

    amqp_notifier = AMQPNotifier(
        database=getenv("DB_NAME", "mox"),
        user=getenv("DB_USER", "mox"),
        password=getenv("DB_PASS", "mox"),
        host=getenv("DB_HOST", "localhost")
    )
