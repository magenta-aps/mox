""" Simple class to relay messages from PostgreSQL notifications
into an AMQP-queue """
import threading
import select
import time
import json
import pika
import psycopg2
from os import getenv


def Heartbeat(amqp_notifier):
    pika_params = pika.ConnectionParameters('localhost')
    pika_connection = pika.BlockingConnection(pika_params)
    amqp = pika_connection.channel()
    amqp.queue_declare(queue='mox.heartbeat')
    while amqp_notifier.ttl > 0:  # Ensure AMQPNotifier is running
        amqp_notifier.ttl -= 1
        print(amqp_notifier.ttl)
        time.sleep(2)
        amqp.basic_publish(exchange='',
                           routing_key='mox.heartbeat',
                           body=str(time.time()))


class AMQPNotifier(threading.Thread):
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
        self.ttl = 50

    def run(self):
        while True:
            self.ttl = 50  # Will be updated at least every 60s
            self.pg_cursor.execute("LISTEN mox_notifications;")
            self.pg_conn.poll()
            self.pg_conn.commit()
            if select.select([self.pg_conn], [], [], 60) == ([], [], []):
                self.amqp.basic_publish(exchange='',
                                        routing_key='mox.heartbeat',
                                        body=str(time.time()))
            else:
                self.pg_conn.poll()
                self.pg_conn.commit()
                while self.pg_conn.notifies:
                    notify = self.pg_conn.notifies.pop(0)
                    payload_dict = json.loads(notify.payload)

                    table = payload_dict['table']
                    objekttype = table[0:table.find('registrering')-1]
                    objecktID = payload_dict['data'][objekttype + '_id']
                    registrering = payload_dict['data']['registrering']
                    livscykluskode = registrering['livscykluskode']

                    amqp_payload = {'beskedtype': 'Notification',
                                    'objecktID': objecktID,
                                    'objekttype': objekttype,
                                    'livscykluskode': livscykluskode}

                    self.amqp.basic_publish(exchange='',
                                            routing_key='mox.notifications',
                                            body=json.dumps(amqp_payload))

if __name__ == '__main__':

    amqp_notifier = AMQPNotifier(
        database=getenv("DB_NAME", "mox"),
        user=getenv("DB_USER", "mox"),
        password=getenv("DB_PASS", "mox"),
        host=getenv("DB_HOST", "localhost")
    )

    heartbeat = threading.Thread(target=Heartbeat, args=[amqp_notifier])
    heartbeat.daemon = True
    amqp_notifier.start()
    heartbeat.start()

    while amqp_notifier.is_alive():
        time.sleep(2)
