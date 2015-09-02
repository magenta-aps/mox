#!/usr/bin/env python


import pika
import sys

#if len(sys.argv) > 1:
message = " ".join(sys.argv[1:]) or "Hello world!"
#else:
#    message = 'Hello world!'

connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        'moxing.dk',
        credentials=pika.credentials.PlainCredentials(
            'Carsten Agger', 
            'xyzxyzxyz')
    )
)

channel = connection.channel()

channel.exchange_declare(exchange='mox', type='headers', durable=True)

channel.basic_publish(
    exchange='mox',
    routing_key='',
    body=message,
    properties=pika.BasicProperties(
        app_id= 'Python Test',
        cluster_id='MOX test',
        content_type= 'application/json',
        headers={ 
        'content': 'Hello world!',
    })
)
#q = channel.queue_declare(exclusive=True).method.queue
#
#channel.basic_publish(
#    exchange='',
#    routing_key='jobs',
#    body=message,
#    properties=pika.BasicProperties(delivery_mode = 2)
#)

print " [x] Sent '{0}'".format(message)

connection.close()

