from datetime import datetime
from dateutil import parser as dateparser
import uuid


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
        headers[Message.HEADER_OBJECTTYPE] = \
            Message.HEADER_OBJECTTYPE_VALUE_DOCUMENT
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


# A message pertaining to an object
class ObjectMessage(Message):

    def __init__(self, objectid, objecttype):
        super(ObjectMessage, self).__init__()
        self.objectid = objectid
        self.objecttype = objecttype

    def getHeaders(self):
        headers = super(ObjectMessage, self).getHeaders()
        headers[self.HEADER_OBJECTID] = self.objectid
        headers[self.HEADER_OBJECTTYPE] = self.objecttype
        return headers


# A message saying that an object has been updated in the database
class NotificationMessage(ObjectMessage):

    HEADER_LIFECYCLE_CODE = "livscykluskode"
    MESSAGE_TYPE = 'notification'

    def __init__(self, objectid, objecttype, lifecyclecode):
        super(NotificationMessage, self).__init__(objectid, objecttype)
        self.lifecyclecode = lifecyclecode

    def getHeaders(self):
        headers = super(NotificationMessage, self).getHeaders()
        headers[Message.HEADER_MESSAGETYPE] = self.MESSAGE_TYPE
        headers[NotificationMessage.HEADER_LIFECYCLE_CODE] = self.lifecyclecode
        return headers

    @staticmethod
    def parse(headers, data=None):
        type = headers[Message.HEADER_MESSAGETYPE]
        if type and type.lower() == NotificationMessage.MESSAGE_TYPE:
            try:
                objectid = headers[Message.HEADER_OBJECTID]
                objecttype = headers[Message.HEADER_OBJECTTYPE]
                lifecyclecode = headers[
                    NotificationMessage.HEADER_LIFECYCLE_CODE
                ]
                return NotificationMessage(objectid, objecttype, lifecyclecode)
            except:
                pass


# A message saying that an object's effective period has begun or ended
class EffectUpdateMessage(ObjectMessage):

    TYPE_BEGIN = 1
    TYPE_END = 2
    TYPE_BOTH = TYPE_BEGIN | TYPE_END

    HEADER_UPDATE_TYPE = "updatetype"
    HEADER_EFFECT_TIME = "effecttime"
    MESSAGE_TYPE = 'effectupdate'

    def __init__(self, objectid, objecttype, updatetype, effecttime):
        super(EffectUpdateMessage, self).__init__(objectid, objecttype)
        self.updatetype = updatetype
        self.effecttime = effecttime

    @property
    def updatetype(self):
        return self._updatetype

    @updatetype.setter
    def updatetype(self, updatetype):
        if type(updatetype) != int:
            raise TypeError
        elif updatetype not in [
            self.TYPE_BEGIN, self.TYPE_END, self.TYPE_BOTH
        ]:
            raise ValueError
        else:
            self._updatetype = updatetype

    @property
    def effecttime(self):
        return self._effecttime

    @effecttime.setter
    def effecttime(self, effecttime):
        if type(effecttime) == datetime:
            self._effecttime = effecttime
        elif isinstance(effecttime, basestring):
            self._effecttime = dateparser.parse(effecttime)
        else:
            raise TypeError

    def getHeaders(self):
        headers = super(EffectUpdateMessage, self).getHeaders()
        headers[self.HEADER_MESSAGETYPE] = self.MESSAGE_TYPE
        headers[self.HEADER_UPDATE_TYPE] = self.updatetype
        headers[self.HEADER_EFFECT_TIME] = self.effecttime
        return headers

    @staticmethod
    def parse(headers, data=None):
        type = headers[Message.HEADER_MESSAGETYPE]
        if type and type.lower() == EffectUpdateMessage.MESSAGE_TYPE:
            try:
                objectid = headers[Message.HEADER_OBJECTID]
                objecttype = headers[Message.HEADER_OBJECTTYPE]
                updatetype = headers[EffectUpdateMessage.HEADER_UPDATE_TYPE]
                effecttime = headers[EffectUpdateMessage.HEADER_EFFECT_TIME]
                return EffectUpdateMessage(
                    objectid, objecttype, updatetype, effecttime
                )
            except:
                pass
