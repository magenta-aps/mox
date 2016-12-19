

class OIOFlaskException(Exception):
    status_code = None  # Please supply in subclass!

    def __init__(self, message, payload=None):
        Exception.__init__(self, message)
        self.message = message
        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        rv['message'] = self.message
        return rv


class NotAllowedException(OIOFlaskException):
    status_code = 403


class NotFoundException(OIOFlaskException):
    status_code = 404


class UnauthorizedException(OIOFlaskException):
    status_code = 401


class AuthorizationFailedException(OIOFlaskException):
    status_code = 403


class BadRequestException(OIOFlaskException):
    status_code = 400


class DBException(OIOFlaskException):

    def __init__(self, status_code, message, payload=None):
        OIOFlaskException.__init__(self, message, payload)
        self.status_code = status_code
