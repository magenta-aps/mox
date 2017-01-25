import json
import pytz
from datetime import datetime
from urllib import urlencode
from PyOIO.OIOCommon.util import parse_time
from PyOIO.OIOCommon.exceptions import ItemNotFoundException
from PyOIO.OIOCommon.exceptions import InvalidOIOException

from PyOIO.OIOCommon.gyldighed import OIOGyldighedContainer
from PyOIO.OIOCommon.publiceret import OIOPubliceretContainer
from PyOIO.OIOCommon.relation import OIORelationContainer
from PyOIO.OIOCommon.egenskab import OIOEgenskabContainer, OIOEgenskab


def requires_load(func):
    def func_wrapper(self, *args, **kwargs):
        self.ensure_load()
        return func(self, *args, **kwargs)
    return func_wrapper


class OIOEntity(object):

    ENTITY_CLASS = "OIOEntity"
    EGENSKABER_KEY = 'egenskaber'
    GYLDIGHED_KEY = None
    PUBLICERET_KEY = None

    egenskaber_keys = ['brugervendtnoegle']
    name_key = 'brugervendtnoegle'
    relation_map = {}

    _registrering_class = None
    _egenskab_class = OIOEgenskab

    def __init__(self, lora, id):
        self.id = id
        self.lora = lora
        self.json = {}
        self._loaded = False
        self._loading = False
        self.registreringer = []

    def __repr__(self):
        return '%s(%s)' % (self.ENTITY_CLASS, self.id)

    def __str__(self):
        return '%s: %s' % (self.ENTITY_CLASS, self.id)

    @classmethod
    def registrering_class(cls, registrering_class):
        cls._registrering_class = registrering_class
        registrering_class._entity_class = cls
        return registrering_class

    @classmethod
    def egenskab_class(cls, egenskab_class):
        cls._egenskab_class = egenskab_class
        egenskab_class._entity_class = cls
        return egenskab_class

    @property
    def path(self):
        return "%s/%s" % (self.basepath, self.id)

    def load(self):
        self._loading = True
        # print "Load %s" % self.path
        params = {
            'registreretfra': '-infinity',
            'registrerettil': 'infinity',
            'virkningfra': '-infinity',
            'virkningtil': 'infinity'
        }

        response = self.lora.request(
            self.lora.host + self.path + "?" + urlencode(params),
            headers=self.get_headers()
        )
        if response.status_code == 200:
            jsondata = json.loads(response.text)
            if jsondata[self.id] is None:
                raise ItemNotFoundException(
                    self.id, self.ENTITY_CLASS, self.path
                )
            print "Load %s %s" % (self.ENTITY_CLASS, self.id)
            self.json = jsondata[self.id][0]
            self.parse_json()
            self.loaded()
        elif response.status_code == 404:
            raise ItemNotFoundException(self.id, self.ENTITY_CLASS, self.path)
        else:
            print "got error %d" % response.status_code
            pass

    def parse_json(self):
        if 'registreringer' not in self.json or \
                len(self.json.get('registreringer')) == 0:
            raise InvalidOIOException(
                "Item %s has no registreringer" % self.id
            )
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(
                self._registrering_class(self, registrering, index)
            )

    def sort_registreringer(self):
        self.registreringer.sort(
            key=lambda registrering: registrering.from_time
        )

    def ensure_load(self):
        if not self._loaded:
            self.load()

    def loaded(self):
        self._loaded = True
        self._loading = False
        self.sort_registreringer()

    def get_headers(self):
        return self.lora.get_headers()

    @requires_load
    def get_registrering(self, time):
        for registrering in self.registreringer:
            if registrering.in_effect(time):
                return registrering

    @property
    def current(self):
        return self.get_registrering(datetime.now(pytz.utc))

    def before(self, registrering=None):
        if registrering is None:
            registrering = self.current
        index = self.registreringer.index(registrering)
        if index > 0:
            return self.registreringer[index - 1]

    def after(self, registrering=None):
        if registrering is None:
            registrering = self.current
        index = self.registreringer.index(registrering)
        if index > -1 and index < len(self.registreringer) - 1:
            return self.registreringer[index + 1]


@OIOEntity.registrering_class
class OIORegistrering(object):

    TIME_INFINITY = 'infinity'
    TIME_NINFINITY = '-infinity'

    from_time = None
    to_time = None

    def __init__(self, entity, data, registrering_number):
        self.entity = entity
        self.json = data
        self.registrering_number = registrering_number
        self.attributter = {}
        self.tilstande = {}
        self.note = data.get('note')
        self.livscykluskode = data['livscykluskode']
        from_time = data.get('fratidspunkt', {}).get('tidsstempeldatotid')
        if from_time:
            self.from_time = parse_time(from_time)
        to_time = data.get('tiltidspunkt', {}).get('tidsstempeldatotid')
        if to_time:
            self.to_time = parse_time(to_time)
        # self.created_by = Bruger(self.lora, data['brugerref'])

        if self.entity.GYLDIGHED_KEY:
            self.gyldigheder = OIOGyldighedContainer.from_json(
                self, self.json['tilstande'][self.entity.GYLDIGHED_KEY]
            )
        if self.entity.PUBLICERET_KEY:
            self.publiceringer = OIOPubliceretContainer.from_json(
                self, self.json['tilstande'][self.entity.PUBLICERET_KEY]
            )
        self._relationer = OIORelationContainer.from_json(
            self, self.json.get('relationer')
        )
        self.egenskaber = OIOEgenskabContainer.from_json(
            self,
            self.json['attributter'][self.entity.EGENSKABER_KEY],
            self.entity._egenskab_class
        )

    def __repr__(self):
        return '%sRegistrering("%s", %s)' % (
            self.entity.ENTITY_CLASS, self.entity.id, self.registrering_number
        )

    def __str__(self):
        return '%sRegistrering: %s "%s", Nr. %s (%s - %s)' % (
            self.entity.ENTITY_CLASS, self.entity.ENTITY_CLASS, self.entity.id,
            self.registrering_number, self.from_time, self.to_time
        )

    @property
    def lora(self):
        return self.entity.lora

    def in_effect(self, time):
        return self.from_time < time and time < self.to_time

    def get_gyldighed(self, time=None):
        gyldighed_items = self.gyldigheder.at(time) if time \
            else self.gyldigheder.current
        if len(gyldighed_items):
            return gyldighed_items[0].gyldighed

    @property
    def gyldighed(self):
        return self.get_gyldighed()

    def get_publiceret(self, time=None):
        publiceret_items = self.publiceringer.at(time) if time \
            else self.publiceringer.current
        if len(publiceret_items):
            return publiceret_items[0].publiceret

    @property
    def publiceret(self):
        return self.get_publiceret()

    def get_egenskab(self, name, must_be_current=True):
        egenskaber = self.egenskaber.current if must_be_current \
            else self.egenskaber
        for egenskab in egenskaber:
            if hasattr(egenskab, name):
                return getattr(egenskab, name)

    @property
    def name(self):
        return getattr(self, self.entity.name_key, None)

    @property
    def type(self):
        if hasattr(self.entity, 'type_key'):
            return getattr(self, self.entity.type_key, None)

    @property
    def relationer(self):
        return self._relationer

    @property
    def before(self):
        return self.entity.before(self)

    @property
    def after(self):
        return self.entity.after(self)

    def __getattr__(self, name):
        if name in self.entity.relation_keys:
            return getattr(self._relationer, name, [])
        if name in self.entity.egenskaber_keys:
            return self.get_egenskab(name)
