""" Simple class to relay messages from PostgreSQL notifications
into an AMQP-queue """
import threading
import select
import time
import json
import pika
import psycopg2
from os import getenv


class Heartbeat(threading.Thread):
    """ Heartbeat thread. Will ensure a heartbeat message approximately
    every two seconds """
    def __init__(self):
        threading.Thread.__init__(self)
        pika_params = pika.ConnectionParameters('localhost')
        pika_connection = pika.BlockingConnection(pika_params)
        self.amqp = pika_connection.channel()
        self.amqp.queue_declare(queue='mox.heartbeat')

    def run(self):
        while True:
            time.sleep(2)
            self.amqp.basic_publish(exchange='',
                                    routing_key='mox.heartbeat',
                                    body=json.dumps(time.time()))


class PgnotifyToAmqp(threading.Thread):
    """ Main notification thread. Will send a heartbeat
    approximately every minute if no messages is
    recieved """
    def __init__(self, database, user, password, host):
        """
        :param database: The PostgreSQL database
        :param user:  The PostgreSQL user
        :param password: The PostgreSQL password
        :param host:  The PostgreSQL hostname
        """
        threading.Thread.__init__(self)
        self.pg_conn = psycopg2.connect(database=database, user=user,
                                        password=password, host=host)
        self.pg_cursor = self.pg_conn.cursor()
        pika_params = pika.ConnectionParameters('localhost')
        pika_connection = pika.BlockingConnection(pika_params)
        self.amqp = pika_connection.channel()
        self.amqp.queue_declare(queue='mox.notifications')
        self.amqp.queue_declare(queue='mox.heartbeat')

    def run(self):
        while True:
            self.pg_cursor.execute("LISTEN mox_notifications;")
            self.pg_conn.poll()
            self.pg_conn.commit()
            if select.select([self.pg_conn], [], [], 60) == ([], [], []):
                print('timeout')
                self.amqp.basic_publish(exchange='',
                                        routing_key='mox.heartbeat',
                                        body=json.dumps(time.time()))
            else:
                self.pg_conn.poll()
                self.pg_conn.commit()
                while self.pg_conn.notifies:
                    notify = self.pg_conn.notifies.pop(0)
                    payload_dict = json.loads(notify.payload)
                    amqp_payload = {}
                    table = payload_dict['table']
                    objekttype = table[0:table.find('registrering')-1]
                    amqp_payload['beskedtype'] = 'Notification'
                    objecktID = payload_dict['data'][objekttype + '_id']
                    amqp_payload['objecktID'] = objecktID
                    amqp_payload['objekttype'] = objekttype
                    lc = payload_dict['data']['registrering']['livscykluskode']
                    amqp_payload['livscykluskode'] = lc
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
    heartbeat = Heartbeat()
    heartbeat.daemon = True
    notify2amqp.start()
    heartbeat.start()

    while notify2amqp.is_alive():
        time.sleep(2)

