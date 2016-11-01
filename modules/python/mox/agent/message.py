class Message(object):

    HEADER_AUTHORIZATION = "autorisation"
    HEADER_MESSAGEID = "beskedID"
    HEADER_MESSAGETYPE = "beskedtype"
    HEADER_MESSAGEVERSION = "beskedversion"
    HEADER_OBJECTREFERENCE = "objektreference"
    HEADER_OBJECTTYPE = "objekttype"
    HEADER_OBJECTTYPE_VALUE_DOCUMENT = "dokument"

    HEADER_TYPE = "type"
    HEADER_TYPE_VALUE_MANUAL = "Manuel"

    HEADER_OBJECTID = "objektID"
    HEADER_OPERATION = "operation"
    HEADER_LIFECYCLE_CODE = "livscykluskode"

    version = 1
    operation = ""

    def __init__(self):
        pass

    def getData(self):
        return {}

    def getHeaders(self):
        return {
            Message.HEADER_MESSAGEID: str(uuid.uuid4()),
            Message.HEADER_MESSAGEVERSION: self.version,
            Message.HEADER_OPERATION: self.operation
        }


class AuthorizedMessage(Message):

    def __init__(self, authorization):
        super(AuthorizedMessage, self).__init__()
        self.authorization = authorization

    def getHeaders(self):
        object = super(AuthorizedMessage, self).getHeaders()
        object[Message.HEADER_AUTHORIZATION] = self.authorization
        return object


class UploadedDocumentMessage(AuthorizedMessage):

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


"""
An message saying that an object has been updated in the database
"""
class NotificationMessage(Message):
    def __init__(self, objectid, objecttype, lifecyclecode):
        super(NotificationMessage, self).__init__()
        self.objectid = objectid
        self.objecttype = objecttype
        self.lifecyclecode = lifecyclecode

    def getHeaders(self):
        headers = super(NotificationMessage, self).getHeaders()
        headers[Message.HEADER_MESSAGETYPE] = 'notification'
        headers[Message.HEADER_OBJECTID] = self.objectid
        headers[Message.HEADER_OBJECTTYPE] = self.objecttype
        headers[Message.HEADER_LIFECYCLE_CODE] = self.lifecyclecode
        return headers

    @staticmethod
    def parse(headers, data=None):
        type = headers[Message.HEADER_MESSAGETYPE]
        if type and type.lower() == 'notification':
            try:
                objectid = headers.get[Message.HEADER_OBJECTID]
                objecttype = headers.get[Message.HEADER_OBJECTTYPE]
                lifecyclecode = headers.get[Message.HEADER_LIFECYCLE_CODE]
                return NotificationMessage(objectid, objecttype, lifecyclecode)
            except KeyError:
                pass
