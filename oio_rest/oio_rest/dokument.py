# encoding: utf-8

from oio_rest import OIORestObject, OIOStandardHierarchy


class Dokument(OIORestObject):
    """
    Implement a Dokument  - manage access to database layer from the API.
    """

    @classmethod
    def gather_registration(cls, input):
        attributes = input.get("attributter", {})
        states = input.get("tilstande", {})
        relations = input.get("relationer", {})
        variants = input.get("varianter", [])
        return {"states": states,
                "attributes": attributes,
                "relations": relations,
                "variants": variants}

class DokumentHierarki(OIOStandardHierarchy):
    """Implement the Dokument Standard."""

    _name = "Dokument"
    _classes = [Dokument]
