import requests
import json
import pytz
from datetime import datetime
from PyOIO.OIOCommon import OIORelation
from PyOIO.OIOCommon.util import parse_time
from PyOIO.OIOCommon.exceptions import ItemNotFoundException
# from PyOIO.organisation.bruger import Bruger
# from PyOIO.organisation.organisation import Organisation

def requires_load(func):
    def func_wrapper(self, *args, **kwargs):
        self.ensure_load()
        return func(self, *args, **kwargs)
    return func_wrapper

class OIOEntity(object):

    ENTITY_CLASS = "OIOEntity"
    EGENSKABER_KEY = 'egenskaber'
    GYLDIGHED_KEY = 'gyldighed'

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

    @staticmethod
    def basepath():
        raise NotImplementedError

    @property
    def path(self):
        return "%s/%s" % (self.basepath(), self.id)

    def load(self):
        self._loading = True
        # print "Load %s" % self.path
        response = requests.get(self.lora.host + self.path, headers=self.get_headers())
        if response.status_code == 200:
            jsondata = json.loads(response.text)
            if jsondata[self.id] is None:
                raise ItemNotFoundException(self.id, self.ENTITY_CLASS, self.path)
            print "Load %s" % self.path
            self.json = jsondata[self.id][0]
            self.parse_json()
            self.loaded()
        elif response.status_code == 404:
            raise ItemNotFoundException(self.id, self.ENTITY_CLASS, self.path)
        else:
            print "got error %d" % response.status_code
            pass

    def parse_json(self):
        pass

    def sort_registreringer(self):
        self.registreringer.sort(key=lambda registrering: registrering.from_time)

    def ensure_load(self):
        if not self._loaded:
            self.load()

    def loaded(self):
        self._loaded = True
        self._loading = False
        self.sort_registreringer()

    # def __getattribute__(self, name):
    #     print "getattr %s" % name
    #     if name not in ['id','lora','json','_loaded','_loading','']:
    #         if not self._loaded and not self._loading:
    #             self.load()
    #     return super(OIOEntity, self).__getattribute__(name)


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
        from_time = data.get('fratidspunkt',{}).get('tidsstempeldatotid')
        if from_time:
            self.from_time = parse_time(from_time)
        to_time = data.get('tiltidspunkt',{}).get('tidsstempeldatotid')
        if to_time:
            self.to_time = parse_time(to_time)
        self.created_by = Bruger(self.lora, data['brugerref'])

    def __repr__(self):
        return '%sRegistrering("%s", %s)' % (self.entity.ENTITY_CLASS, self.entity.id, self.registrering_number)

    def __str__(self):
        return '%sRegistrering: %s "%s", Nr. %s (%s - %s)' % (self.entity.ENTITY_CLASS, self.entity.ENTITY_CLASS, self.entity.id, self.registrering_number, self.from_time, self.to_time)

    @property
    def lora(self):
        return self.entity.lora

    def in_effect(self, time):
        return self.from_time < time and time < self.to_time

    def get_egenskab(self, name):
        for egenskab in self.egenskaber:
            if hasattr(egenskab, name):
                return getattr(egenskab, name)

    @property
    def egenskaber(self):
        return self.attributter[self.entity.EGENSKABER_KEY]

    def set_egenskaber(self, egenskaber):
        self.attributter[self.entity.EGENSKABER_KEY] = egenskaber

    @property
    def brugervendtnoegle(self):
        return self.get_egenskab('brugervendtnoegle')

    @property
    def gyldighed(self):
        return self.tilstande[self.entity.GYLDIGHED_KEY]

    def set_gyldighed(self, gyldighed):
        self.tilstande[self.entity.GYLDIGHED_KEY] = gyldighed

    @property
    def relationer(self):
        return self._relationer

    def set_relationer(self, relationer):
        self._relationer = relationer

    def tilhoerer(self, entity_class=None):
        tilhoerer = self.relationer.get(OIORelation.TYPE_TILHOERER).current
        return [
            relation.item
            for relation in tilhoerer
            if relation.item is not None and
            (entity_class is None or relation.item.ENTITY_CLASS == entity_class)
        ]

    @property
    def before(self):
        return self.entity.before(self)

    @property
    def after(self):
        return self.entity.after(self)