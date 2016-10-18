
class InvalidOIOException(Exception):

    def __init__(self, e):
        super(InvalidOIOException, self).__init__('Invalid OIO: %s' % e)


class InvalidUUIDException(InvalidOIOException):
    def __init__(self, uuid):
        super(InvalidUUIDException, self).__init__("%s is not a valid UUID" % uuid)


class InvalidObjectTypeException(InvalidOIOException):
    def __init__(self, objecttype):
        super(InvalidObjectTypeException, self).__init__("%s is not a valid object type" % objecttype)


class TokenException(Exception):
    def __init__(self, message):
        super(TokenException, self).__init__(message)
