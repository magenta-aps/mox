from data import Item, ItemContainer
from exceptions import InvalidOIOException


class OIOGyldighed(Item):
    gyldige_tilstande = ['Aktiv', 'Inaktiv']

    def __init__(self, registrering, data):
        super(OIOGyldighed, self).__init__(registrering, data)
        gyldighed = data['gyldighed']
        if gyldighed in OIOGyldighed.gyldige_tilstande:
            self.gyldighed = gyldighed
        else:
            raise InvalidOIOException('Invalid gyldighed "%s"' % gyldighed)

    @staticmethod
    def from_json(registrering, json):
        return OIOGyldighed(registrering, json)


class OIOGyldighedContainer(ItemContainer):

    @staticmethod
    def from_json(registrering, json):
        container = OIOGyldighedContainer()
        for gyldighed in json:
            container.append(OIOGyldighed.from_json(registrering, gyldighed))
        return container
