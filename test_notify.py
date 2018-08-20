import time
import json
import pika
import psycopg2

class PgnotifyToAmqp(object):
    def __init__(self):
        # TODO: Fix hard-coded connection params!!!!
        self.pg_conn = psycopg2.connect(database='mox', user='mox', 
                                        password='mox', host='localhost')
        self.pg_cursor = self.pg_conn.cursor()

        pika_params = pika.ConnectionParameters('localhost')
        pika_connection = pika.BlockingConnection(pika_params)
        self.amqp = pika_connection.channel()
        self.amqp.queue_declare(queue='mox.notifications')

    def main(self):
        while True:
            time.sleep(1)
            print('Sleeping')
            self.pg_cursor.execute("LISTEN events;")
            self.pg_conn.poll()
            self.pg_conn.commit()
            while self.pg_conn.notifies:
                notify = self.pg_conn.notifies.pop(0)
                #print(notify.payload)
                #print(notify.channel)
                #print(notify.pid)

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

                self.amqp.basic_publish(exchange='',
                                        routing_key='mox.notifications',
                                        body=json.dumps(amqp_payload))
                
if __name__ == '__main__':
    notify2amqp = PgnotifyToAmqp()
    notify2amqp.main()
