""" Simple class to relay messages from PostgreSQL notifications
into an AMQP-queue """
import time
import json
import pika
import psycopg2
from os import getenv

class PgnotifyToAmqp(object):
    def __init__(self, database, user, password, host):
        """

        :param database:
        :param user:
        :param password:
        :param host:
        """

        self.pg_conn = psycopg2.connect(database=database, user=user,
                                        password=password, host=host)
        self.pg_cursor = self.pg_conn.cursor()

        pika_params = pika.ConnectionParameters('localhost')
        pika_connection = pika.BlockingConnection(pika_params)
        self.amqp = pika_connection.channel()
        self.amqp.queue_declare(queue='mox.notifications')
        self.amqp.queue_declare(queue='mox.heartbeat')

    def read_pg_notify(self):
        """ Read all notifications currently in queue
        :return: """
        payloads = []
        self.pg_cursor.execute("LISTEN mox_notifications;")
        self.pg_conn.poll()
        self.pg_conn.commit()
        while self.pg_conn.notifies:
            notify = self.pg_conn.notifies.pop(0)
            payload_dict = json.loads(notify.payload)
            amqp_payload = {}
            table = payload_dict['table']
            objekttype = table[0:table.find('registrering')-1]
            amqp_payload['beskedtype'] = 'Notificaion'
            objecktID = payload_dict['data'][objekttype + '_id']
            amqp_payload['objecktID'] = objecktID
            amqp_payload['objekttype'] = objekttype
            lck = payload_dict['data']['registrering']['livscykluskode']
            amqp_payload['livscykluskode'] = lck
            payloads.append(amqp_payload)
        return payloads

    def main(self):
        while True:
            time.sleep(2)
            self.amqp.basic_publish(exchange='',
                                    routing_key='mox.heartbeat',
                                    body=json.dumps(time.time()))

            payloads = self.read_pg_notify()
            for amqp_payload in payloads:
                self.amqp.basic_publish(exchange='',
                                        routing_key='mox.notifications',
                                        body=json.dumps(amqp_payload))

if __name__ == '__main__':

    notify2amqp = PgnotifyToAmqp(
        database=getenv("DB_NAME", "mox"),
        user=getenv("DB_USER", "mox"),
        password=getenv("DB_PASS", "mox"),
        host=getenv("DB_HOST", "localhost")
    )

    notify2amqp.main()
