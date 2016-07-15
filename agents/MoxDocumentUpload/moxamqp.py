import amqp
import uuid
import json
import time

class Message(object):

    HEADER_AUTHORIZATION = "autorisation"
    HEADER_MESSAGEID = "beskedID"
    HEADER_MESSAGEVERSION = "beskedversion"
    HEADER_OBJECTREFERENCE = "objektreference"
    HEADER_OBJECTTYPE = "objekttype"
    HEADER_OBJECTTYPE_VALUE_DOCUMENT = "dokument"

    HEADER_TYPE = "type"
    HEADER_TYPE_VALUE_MANUAL = "Manuel"

    HEADER_OBJECTID = "objektID"
    HEADER_OPERATION = "operation"

    version = 1
    operation = ""

    def __init__(self, authorization):
        self.authorization = authorization

    def getData(self):
        return {}

    def getHeaders(self):
        return {
            Message.HEADER_AUTHORIZATION: self.authorization,
            Message.HEADER_MESSAGEID: str(uuid.uuid4()),
            Message.HEADER_MESSAGEVERSION: self.version,
            Message.HEADER_OPERATION: self.operation
        }


class UploadedDocumentMessage(Message):

    KEY_UUID = "uuid"
    operation = "upload"

    def __init__(self, uuid, authorization):
        super(UploadedDocumentMessage, self).__init__(authorization)
        self.uuid = uuid

    def getData(self):
        object = super(UploadedDocumentMessage, self).getData()
        object[UploadedDocumentMessage.KEY_UUID] = str(self.uuid)
        return object

    def getHeaders(self):
        headers = super(UploadedDocumentMessage, self).getHeaders()
        headers[Message.HEADER_OBJECTTYPE] = Message.HEADER_OBJECTTYPE_VALUE_DOCUMENT
        headers[Message.HEADER_TYPE] = Message.HEADER_TYPE_VALUE_MANUAL
        headers[Message.HEADER_OBJECTREFERENCE] = str(self.uuid)
        return headers

    @staticmethod
    def parse(headers, data):
        operation = headers[Message.HEADER_OPERATION]
        if operation == UploadedDocumentMessage.OPERATION:
            authorization = headers.get(Message.HEADER_AUTHORIZATION)
            uuid = data.get(UploadedDocumentMessage.KEY_UUID)
            if authorization is not None and uuid is not None:
                return UploadedDocumentMessage(uuid, authorization)




class MessageInterface(object):
    def __init__(self, username, password, host, queue, exchange=''):

        if ":" not in host:
            host += ":5672"

        self.queue = queue
        self.exchange = exchange
        self.connection = amqp.Connection(host, username, password)
        self.connection.connect()
        self.channel = amqp.Channel(self.connection)
        self.channel.open()
        self.channel.queue_declare(queue, durable=False, exclusive=False, auto_delete=False)




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

class NoSuchJob(Exception):
    def __init__(self, message):
        super(NoSuchJob, self).__init__(message)

