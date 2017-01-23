#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class OrganisationEnhed(OIOEntity):
    """Represents the OIO information model 1.1 OrganisationEnhed
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'OrganisationEnhed'
    EGENSKABER_KEY = 'organisationenhedegenskaber'
    GYLDIGHED_KEY = 'organisationenhedgyldighed'
    basepath = '/organisation/organisationenhed'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['enhedsnavn']
    name_key = 'enhedsnavn'

    relation_keys = [
        'adresser', 'ansatte', 'branche', 'enhedstype', 'opgaver',
        'overordnet', 'produktionsenhed', 'skatteenhed', 'tilhoerer',
        'tilknyttedeorganisationer', 'tilknyttedeenheder',
        'tilknyttedefunktioner', 'tilknyttedebrugere',
        'tilknyttedeinteressefaellesskaber', 'tilknyttedeitsystemer',
        'tilknyttedepersoner'
    ]
