from data import Item, ItemContainer

class OIOEgenskab(Item):
    def __init__(self, registrering, data):
        super(OIOEgenskab, self).__init__(registrering, data)
        self.brugervendtnoegle = data['brugervendtnoegle']

    @property
    def name(self):
        return self.brugervendtnoegle

    def __repr__(self):
        return '%sEgenskab("%s - %s")' % (self.registrering.entity.ENTITY_CLASS, self.brugervendtnoegle, self.name)

    def __str__(self):
        return '%sEgenskab: %s "%s - %s"' % (self.registrering.entity.ENTITY_CLASS, self.registrering.entity.ENTITY_CLASS, self.brugervendtnoegle, self.name)


class OIOEgenskabContainer(ItemContainer):
    pass