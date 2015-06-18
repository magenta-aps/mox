#!/usr/bin/env python
# encoding: utf-8


import pika
import time
from pika.exceptions import ConnectionClosed

connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        'moxing.dk',
        credentials=pika.credentials.PlainCredentials(
            'Carsten Agger',
            'xyzxyzxyz'
        )
    )
)

channel = connection.channel()

result = channel.queue_declare(exclusive=True)
channel.queue_bind(exchange='mox',
                   queue=result.method.queue)

def callback(ch, method, properties, body):
    # Do whatever you want here, e.g. process MOX messages.
    print " [x] Received {0}".format(body)
    print " [x] Channel: {0}".format(channel)
    print " [x] Method: {0}".format(method)
    print " [x] Properties: {0}".format(properties)
    ch.basic_ack(delivery_tag = method.delivery_tag)

 
channel.basic_consume(callback, queue=result.method.queue)

print ' [*] Waiting for messages. To exit press CTRL+C!'

try:
    channel.start_consuming()
except pika.exceptions.ConnectionClosed:
    print "Server stopped!"
else: 
    raise
