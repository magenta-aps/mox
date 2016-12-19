from data import Item, ItemContainer
from exceptions import InvalidObjectTypeException


class OIORelationContainer(object):

    items = None

    def __init__(self, registrering):
        self.items = {}
        self.registrering = registrering

    @staticmethod
    def from_json(registrering, data):
        relationcontainer = OIORelationContainer(registrering)
        if data is not None:
            for type in registrering.entity.relation_keys:
                if type in data:
                    for relation in data[type]:
                        relationcontainer.add(
                            type,
                            OIORelation.from_json(registrering, relation, type)
                        )
        return relationcontainer

    def add(self, type, item):
        if type not in self.items:
            self.items[type] = ItemContainer()
        self.items[type].append(item)

    def get(self, key, default=None):
        return self.items.get(key, default)

    def get_entity_class(self, key):
        entity_class = OIORelation.relation_map.get(key)
        if entity_class == OIORelation.REFER_OWN_CLASS:
            return self.registrering.entity.ENTITY_CLASS
        return entity_class

    # def __getattr__(self, name):
    #     if name in self.registrering.entity.relation_keys:
    #         map = {}
    #         for relation in self.get(name, []):
    #             if relation.item:
    #                 entity_class = relation.item.ENTITY_CLASS
    #                 if entity_class not in map:
    #                     map[entity_class] = []
    #                 map[entity_class].append(relation.item)
    #         return map

    def __getattr__(self, name):
        return self.get(name, [])


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
    TYPE_INTERESSEFAELLESSKABSTYPE = 'interessefaellesskabstype'
    TYPE_BRANCHE = 'branche'
    TYPE_OVERORDNET = 'overordnet'
    TYPE_BRUGERTYPER = 'brugertyper'
    TYPE_EJER = 'ejer'
    TYPE_ANSVARLIG = 'ansvarlig'
    TYPE_REDAKTOER = 'redaktoer'

    types = [
        TYPE_TILHOERER, TYPE_ORGANISATION, TYPE_ENHED, TYPE_FUNKTION,
        TYPE_INTERESSEFAELLESSKAB, TYPE_ITSYSTEM, TYPE_BRUGER, TYPE_PERSON,
        TYPE_OPGAVE, TYPE_SYSTEMTYPE, TYPE_ADRESSE, TYPE_VIRKSOMHED,
        TYPE_ORGANISATIONFUNKTIONSTYPE, TYPE_INTERESSEFAELLESSKABSTYPE,
        TYPE_BRANCHE, TYPE_OVERORDNET, TYPE_BRUGERTYPER, TYPE_EJER,
        TYPE_ANSVARLIG, TYPE_REDAKTOER
    ]

    REFER_OWN_CLASS = '__self__'

    relation_map = {
        'tilhoerer': 'Organisation',
        'tilknyttedeorganisationer': 'Organisation',
        'tilknyttedeenheder': 'OrganisationEnhed',
        'tilknyttedefunktioner': 'OrganisationFunktion',
        'tilknyttedebrugere': 'Bruger',
        'tilknyttedeinteressefaellesskaber': 'Interessefaellesskab',
        'tilknyttedeitsystemer': 'Itsystem',
        'tilknyttedepersoner': 'Person',
        'interessefaellesskabstype': 'Klasse',
        'brugertyper': 'Klasse',
        'systemtyper': 'Klasse',
        'opgaver': 'Klasse',
        'adresser': 'Adresse',
        'branche': 'Klasse',
        'overordnet': REFER_OWN_CLASS,
        'ansatte': 'Person',
        'myndighed': 'Myndighed',
        'myndighedstype': 'Klasse',
        'produktionsenhed': 'Virksomhed',
        'skatteenhed': 'Virksomhed',
        'virksomhed': 'Virksomhed',
        'virksomhedstype': 'Klasse',
        'enhedstype': 'Klasse',
        'organisatoriskfunktionstype': 'Klasse',
        'ansvarlig': 'Aktoer',
        'ejer': 'Aktoer',
        'facettilhoer': 'Klassifikation',
        'redaktoerer': 'Aktoer',
        'erstatter': 'Klasse',
        'facet': 'Facet',
        'lovligekombinationer': 'Klasse',
        'mapninger': 'Klasse',
        'sideordnede': 'Klasse',
        'tilfoejelser': 'Klasse'
    }

    def __init__(self, registrering, data, type):
        super(OIORelation, self).__init__(registrering, data)
        self.uuid = data.get('uuid')
        self.urn = data.get('urn')
        self.type = type

    @property
    def item(self):
        if self.uuid:
            try:
                return self.registrering.lora.get_object(
                    self.uuid, self.relation_map[self.type]
                )
            except InvalidObjectTypeException:
                pass

    @staticmethod
    def from_json(registrering, json, type):
        return OIORelation(registrering, json, type)

    def __str__(self):
        return "Relation from %s to %s (%s)" % (
            self.registrering.entity, self.uuid, self.virkning
        )

    def __repr__(self):
        return str(self)

    # Lookups on other attributes are sent to the referred object
    def __getattr__(self, name):
        try:
            return getattr(self.item, name)
        except:
            pass
