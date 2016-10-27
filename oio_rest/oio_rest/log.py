# encoding: utf-8

from oio_rest import OIORestObject, OIOStandardHierarchy


class LogHaendelse(OIORestObject):
    """
    Implement a log entry  - manage access to database layer from the API.
    """
    pass


class LogHierarki(OIOStandardHierarchy):
    """Implement the LogHaendelse Standard."""

    _name = "Log"
    _classes = [LogHaendelse]
