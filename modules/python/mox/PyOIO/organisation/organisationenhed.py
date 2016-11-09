#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class OrganisationEnhed(OIOEntity):
    """Represents the OIO information model 1.1 OrganisationEnhed
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'OrganisationEnhed'
    EGENSKABER_KEY = 'organisationenhedegenskaber'
    GYLDIGHED_KEY = 'organisationenhedgyldighed'
    basepath = '/organisation/organisationenhed'

    egenskaber_keys = ['enhedsnavn']


@OrganisationEnhed.registrering_class
class OrganisationEnhedRegistrering(OIORegistrering):

    @property
    def enhedsnavn(self):
        return self.get_egenskab('enhedsnavn')

    @property
    def name(self):
        return self.enhedsnavn


@OrganisationEnhed.egenskab_class
class OrganisationEnhedEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationEnhedEgenskab, self).__init__(registrering, data)
        self.enhedsnavn = data.get('enhedsnavn')

    @property
    def name(self):
        return self.enhedsnavn

