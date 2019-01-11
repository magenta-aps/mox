# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import json


def load_json_message(message):
    try:
        return json.loads(message)['message']
    except ValueError:
        return message


class InvalidOIOException(Exception):
    def __init__(self, e):
        super(InvalidOIOException, self).__init__('Invalid OIO: %s' % e)


class InvalidUUIDException(InvalidOIOException):
    def __init__(self, uuid):
        super(InvalidUUIDException, self).__init__(
            "%s is not a valid UUID" % uuid
        )


class InvalidObjectTypeException(InvalidOIOException):
    def __init__(self, objecttype):
        super(InvalidObjectTypeException, self).__init__(
            "%s is not a valid object type" % objecttype
        )


class TokenException(Exception):
    def __init__(self, message):
        super(TokenException, self).__init__(load_json_message(message))


class ItemNotFoundException(Exception):
    def __init__(self, uuid, objecttype, url):
        super(ItemNotFoundException, self).__init__(
            "Item %s not found as a %s (tried %s)" % (uuid, objecttype, url)
        )


class RestAccessException(Exception):
    def __init__(self, message):
        super(RestAccessException, self).__init__(load_json_message(message))
