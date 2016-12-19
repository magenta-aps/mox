from data import Item, ItemContainer


class OIOEgenskab(Item):
    def __init__(self, registrering, data):
        super(OIOEgenskab, self).__init__(registrering, data)
        self.brugervendtnoegle = data['brugervendtnoegle']

    @property
    def name(self):
        return self.brugervendtnoegle

    def __repr__(self):
        return '%sEgenskab("%s - %s")' % (
            self.registrering.entity.ENTITY_CLASS,
            self.brugervendtnoegle, self.name
        )

    def __str__(self):
        return '%sEgenskab: %s "%s - %s"' % (
            self.registrering.entity.ENTITY_CLASS,
            self.registrering.entity.ENTITY_CLASS,
            self.brugervendtnoegle, self.name
        )

    def __getattr__(self, name):
        if name in self.registrering.entity.egenskaber_keys:
            return self.get(name, u'')


class OIOEgenskabContainer(ItemContainer):

    @staticmethod
    def from_json(registrering, data, egenskab_class):
        egenskaber = OIOEgenskabContainer()
        for egenskab in data:
            egenskaber.append(egenskab_class(registrering, egenskab))
        return egenskaber
