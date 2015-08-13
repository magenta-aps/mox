from build_registration import build_registration, restriction_to_registration


class OIOFlaskException(Exception):
    status_code = None  # Please supply in subclass!

    def __init__(self, message, payload=None):
        Exception.__init__(self)
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


class BadRequestException(OIOFlaskException):
    status_code = 400
