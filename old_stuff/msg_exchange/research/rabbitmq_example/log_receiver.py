#!/usr/bin/env python
# encoding: utf-8


import pika
import time
import sys
from pika.exceptions import ConnectionClosed

try:
    tag = sys.argv[1]
except IndexError:
    tag = 'x'
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))

channel = connection.channel()

result = channel.queue_declare(exclusive=True)
channel.queue_bind(exchange='logs',
                   queue=result.method.queue)

def callback(ch, method, properties, body):
    # Do whatever you want here, e.g. process MOX messages.
    vowelize = lambda str: ''.join(c for c in str if c in "aeiouyæøå")
    vowels = len(vowelize(body))
    print " [{0}] Received {1}".format(tag, body)
#    print " [x] Channel: {0}".format(channel)
#    print " [x] Method: {0}".format(method)
#    print " [x] Properties: {0}".format(properties)
    time.sleep(vowels)
    print " [{0}] Done ({1})".format(tag, vowels)
    ch.basic_ack(delivery_tag = method.delivery_tag)


    
channel.basic_consume(callback, queue=result.method.queue)

print ' [*] Waiting for messages. To exit press CTRL+C!'

try:
    channel.start_consuming()
except pika.exceptions.ConnectionClosed:
    print "Server stopped!"
else: 
    raise
