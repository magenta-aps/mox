# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


class OIOFlaskException(Exception):
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


class GoneException(OIOFlaskException):
    status_code = 410


class DBException(OIOFlaskException):
    def __init__(self, status_code, *args, payload=None):
        OIOFlaskException.__init__(self, *args, payload)
        self.status_code = status_code
