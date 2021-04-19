# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


class OIOException(Exception):
    status_code = None  # Please supply in subclass!

    def __init__(self, *args, payload=None):
        Exception.__init__(self, *args)
        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        if self.args:
            rv["message"] = self.args[0]

            if len(self.args) > 1:
                rv["context"] = self.args[1:]

        return rv


class NotAllowedException(OIOException):
    status_code = 403


class NotFoundException(OIOException):
    status_code = 404


class UnauthorizedException(OIOException):
    status_code = 401


class AuthorizationFailedException(OIOException):
    status_code = 403


class BadRequestException(OIOException):
    status_code = 400


class GoneException(OIOException):
    status_code = 410


class DBException(OIOException):
    def __init__(self, status_code, *args, payload=None):
        OIOException.__init__(self, *args, payload)
        self.status_code = status_code
