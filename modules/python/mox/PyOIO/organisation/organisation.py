#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class Organisation(OIOEntity):
    """Represents the OIO information model 1.1 Organisation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Organisation'
    EGENSKABER_KEY = 'organisationegenskaber'
    GYLDIGHED_KEY = 'organisationgyldighed'
    basepath = '/organisation/organisation'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['organisationsnavn']
    name_key = 'organisationsnavn'


@Organisation.registrering_class
class OrganisationRegistrering(OIORegistrering):
    pass


@Organisation.egenskab_class
class OrganisationEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationEgenskab, self).__init__(registrering, data)
        self.organisationsnavn = data.get('organisationsnavn')

    @property
    def name(self):
        return self.organisationsnavn
