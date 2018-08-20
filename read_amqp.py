import pika

connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()


channel.queue_declare(queue='mox.notifications')

def callback(ch, method, properties, body):
        print(" [x] Received %r" % body)


channel.basic_consume(callback,
                      queue='mox.notifications',
                      no_ack=True)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
