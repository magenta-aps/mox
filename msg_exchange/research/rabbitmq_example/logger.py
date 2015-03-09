#!/usr/bin/env python


import pika
import sys

#if len(sys.argv) > 1:
message = " ".join(sys.argv[1:]) or "Hello world!"
#else:
#    message = 'Hello world!'

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))

channel = connection.channel()

channel.exchange_declare(exchange='logs', type='fanout')

channel.basic_publish(
    exchange='logs',
    routing_key='',
    body=message,
    properties=pika.BasicProperties()
)

print " [x] Log: '{0}'".format(message)

connection.close()

