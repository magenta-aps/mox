import pika
import uuid
import json
import time
import threading


class MessageInterface(object):

    def __init__(self, username, password, host, exchange):

        try:
            self.connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host=host,
                    credentials=pika.PlainCredentials(username, password)
                )
            )
        except pika.exceptions.ConnectionClosed:
            raise CannotConnectException(host)
        except pika.exceptions.ProbableAuthenticationError:
            raise InvalidCredentialsException(host, username)

        self.channel = self.connection.channel()
        self.exchange = exchange

    def close(self):
        self.channel.close()


class MessageSender(MessageInterface):

    appId = None
    clusterId = None
    replyQueues = []
    replyDeleters = []
    replyDeletePeriod = 3600

    def __init__(self, username, password, host, exchange):
        super(MessageSender, self).__init__(username, password, host, exchange)

    def setAppId(self, appId):
        self.appId = appId

    def getStandardProperties(self):
        return pika.spec.BasicProperties(
            message_id=str(uuid.uuid4()),
            timestamp=int(time.time()),
            app_id=self.appId,
            cluster_id=self.clusterId
        )

    def send(self, message, replyCallback=None):
        data = json.dumps(message.getData())
        properties = self.getStandardProperties()
        properties.headers = message.getHeaders()

        replyQueue = "reply-%s" % str(uuid.uuid4())
        properties.correlation_id = replyQueue
        properties.reply_to = replyQueue
        self.channel.queue_declare(
            replyQueue, durable=False, exclusive=False, auto_delete=True
        )

        self.replyQueues.append(replyQueue)

        # Remove the queue after a given time (default is one hour)
        cleanupTimer = threading.Timer(
            self.replyDeletePeriod,
            self.channel.queue_delete,
            args=[replyQueue]
        )
        cleanupTimer.start()
        self.replyDeleters.append(cleanupTimer)

        if replyCallback:
            # Register a reply queue
            self.channel.basic_consume(
                replyCallback, replyQueue, no_ack=True, exclusive=False
            )

        self.channel.basic_publish(self.exchange, '', data, properties)
        return replyQueue

    def close(self):
        for replyDeleter in self.replyDeleters:
            replyDeleter.cancel()
        for replyQueue in self.replyQueues:
            self.channel.queue_delete(replyQueue)
        super(MessageSender, self).close()

    def getReply(self, replyQueue):
        (method, properties, body) = self.channel.basic_get(replyQueue)
        return (properties, body)


class MessageListener(MessageInterface):

    def __init__(self, username, password, host, exchange,
                 queue_name=None, queue_parameters={}):
        super(MessageListener, self).__init__(
            username, password, host, exchange
        )

        parameters = {
            'durable': False, 'exclusive': False, 'auto_delete': False
        }
        parameters.update(queue_parameters)

        if isinstance(queue_name, basestring) and len(queue_name) > 0:
            self.queue = queue_name
        else:
            self.queue = str(uuid.uuid4())
        self.channel.queue_declare(self.queue, **parameters)
        self.channel.queue_bind(self.queue, self.exchange)

    def close(self):
        self.channel.queue_unbind(self.queue, self.exchange)
        self.channel.queue_delete(self.queue)
        super(MessageListener, self).close()

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
        self.channel.basic_consume(
            self.callback, queue=self.queue, no_ack=True
        )
        try:
            self.channel.start_consuming()
        except KeyboardInterrupt:
            self.close()
            raise


class NoSuchJob(Exception):
    def __init__(self, message):
        super(NoSuchJob, self).__init__(message)


class CannotConnectException(Exception):
    def __init__(self, host):
        super(CannotConnectException, self).__init__(
            "Cannot connect to AMQP service at %s" % host
        )


class InvalidCredentialsException(Exception):
    def __init__(self, host, username):
        super(InvalidCredentialsException, self).__init__(
            "Cannot authenticate to host %s as user %s: "
            "Incorrect password" % (host, username)
        )
