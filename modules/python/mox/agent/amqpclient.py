import pika
import uuid
import json
import time


class MessageInterface(object):
    def __init__(self, username, password, host, queue, exchange='', queue_parameters={}):

        #if ":" not in host:
        #    host += ":5672"

        self.queue = queue
        self.exchange = exchange
        self.connection = pika.BlockingConnection(pika.ConnectionParameters(host=host, credentials=pika.PlainCredentials(username, password)))
        self.channel = self.connection.channel()

        parameters = {'durable': False, 'exclusive': False, 'auto_delete': False}
        parameters.update(queue_parameters)

        self.channel.queue_declare(queue, **parameters)


class MessageSender(MessageInterface):

    appId = None
    clusterId = None
    replyQueue = None
    replyConsumer = None

    def __init__(self, username, password, host, queue, exchange=''):
        super(MessageSender, self).__init__(username, password, host, queue, exchange)

    def setAppId(self, appId):
        self.appId = appId

    def getStandardProperties(self):
        properties = {
            'message_id': str(uuid.uuid4()),
            'timestamp': int(time.time())
        }
        if self.appId is not None:
            properties['app_id'] = self.appId
        if self.clusterId is not None:
            properties['cluster_id'] = self.clusterId

        return properties

    def send(self, message):
        data = json.dumps(message.getData())
        properties = self.getStandardProperties()
        properties['application_headers'] = message.getHeaders()
        replyQueue = str(uuid.uuid4())
        properties['correlation_id'] = replyQueue
        properties['reply_to'] = replyQueue
        amqpMessage = amqp.basic_message.Message(data, **properties)

        self.channel.basic_publish(amqpMessage, self.exchange, self.queue)
        self.channel.queue_declare(replyQueue, durable=False, exclusive=True, auto_delete=True)
        return replyQueue

    def getJobStatus(self, replyQueue):
        try:
            reply = self.channel.basic_get(replyQueue)
        except amqp.exceptions.NotFound:
            raise NoSuchJob(replyQueue)
        if reply is not None:
            return reply.body


class MessageListener(MessageInterface):

    def __init__(self, username, password, host, queue, queue_parameters={}):
        super(MessageListener, self).__init__(username, password, host, queue, None, queue_parameters)

    def callback(self, channel, method, properties, body):
        """Generic callback function for MOX agents."""
        # TODO: Maybe always do SAML authentication here.
        pass

    def run(self):
        # wait and listen to queue.
        if not self.queue:
            print "Please specify queue before running!"
            return
        
        print ' [*] Waiting for messages. To exit press CTRL+C'
        self.channel.basic_qos(prefetch_count=1)
        self.channel.basic_consume(self.callback, queue=self.queue, no_ack=True)
        self.channel.start_consuming()


class NoSuchJob(Exception):
    def __init__(self, message):
        super(NoSuchJob, self).__init__(message)

