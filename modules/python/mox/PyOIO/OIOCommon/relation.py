from virkning import Virkning
from data import Item, ItemContainer

class OIORelationContainer(object):

    items = None

    def __init__(self):
        self.items = {}

    @staticmethod
    def from_json(registrering, data):
        relationcontainer = OIORelationContainer()
        for type in OIORelation.types:
            if type in data:
                for relation in data[type]:
                    relationcontainer.add(type, OIORelation.from_json(registrering, relation))
        return relationcontainer

    def add(self, type, item):
        if not type in self.items:
            self.items[type] = ItemContainer()
        self.items[type].append(item)

    def get(self, key, default=None):
        return self.items.get(key, default)

class OIORelation(Item):

    TYPE_TILHOERER = 'tilhoerer'
    TYPE_ORGANISATION = 'tilknyttedeorganisationer'
    TYPE_ENHED = 'tilknyttedeenheder'
    TYPE_FUNKTION = 'tilknyttedefunktioner'
    TYPE_INTERESSEFAELLESSKAB = 'tilknyttedeinteressefaelleskaber'
    TYPE_ITSYSTEM = 'tilknyttedeitsystemer'
    TYPE_BRUGER = 'tilknyttedebrugere'
    TYPE_PERSON = 'tilknyttedepersoner'
    TYPE_OPGAVE = 'opgaver'
    TYPE_SYSTEMTYPE = 'systemtyper'
    TYPE_ADRESSE = 'adresser'
    TYPE_VIRKSOMHED = 'virksomhed'
    TYPE_ORGANISATIONFUNKTIONSTYPE = 'organisatoriskfunktionstype'

    types = [
        TYPE_TILHOERER, TYPE_ORGANISATION, TYPE_ENHED, TYPE_FUNKTION,
        TYPE_INTERESSEFAELLESSKAB, TYPE_ITSYSTEM, TYPE_BRUGER, TYPE_PERSON,
        TYPE_OPGAVE, TYPE_SYSTEMTYPE, TYPE_ADRESSE
    ]

    def __init__(self, registrering, uuid, data):
        super(OIORelation, self).__init__(registrering, data)
        self.uuid = uuid

    @property
    def item(self):
        return self.registrering.lora.get_object(self.uuid)

    @staticmethod
    def from_json(registrering, json):
        return OIORelation(registrering, json['uuid'], json)

    def __str__(self):
        return "Relation from %s to %s (%s)" % (self.registrering.entity, self.uuid, self.virkning)

    def __repr__(self):
        return str(self)