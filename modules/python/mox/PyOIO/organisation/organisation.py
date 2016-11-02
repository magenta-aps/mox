#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIORelation, OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighed, OIOGyldighedContainer


class Organisation(OIOEntity):
    """Represents the OIO information model 1.1 Organisation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Organisation'
    EGENSKABER_KEY = 'organisationegenskaber'
    GYLDIGHED_KEY = 'organisationgyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the Organisation
        """
        super(Organisation, self).__init__(lora, id)

    @staticmethod
    def basepath():
        return "/organisation/organisation"


@Organisation.registrering_class
class OrganisationRegistrering(OIORegistrering):
    pass


@Organisation.egenskab_class
class OrganisationEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationEgenskab, self).__init__(registrering, data)
        self.organisationsnavn = data.get('organisationsnavn') # 0..1

    @property
    def name(self):
        return self.organisationsnavn
