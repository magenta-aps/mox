from data import Item, ItemContainer
from exceptions import InvalidOIOException


class OIOPubliceret(Item):
    tilstande = ['Publiceret', 'IkkePubliceret']

    def __init__(self, registrering, data):
        super(OIOPubliceret, self).__init__(registrering, data)
        publiceret = data['publiceret']
        if publiceret in OIOPubliceret.tilstande:
            self.publiceret = publiceret
        else:
            raise InvalidOIOException('Invalid publiceret "%s"' % publiceret)

    # @property
    # def value(self):
    #     return self.publiceret

    @staticmethod
    def from_json(registrering, json):
        return OIOPubliceret(registrering, json)


class OIOPubliceretContainer(ItemContainer):

    @staticmethod
    def from_json(registrering, json):
        container = OIOPubliceretContainer()
        for publiceret in json:
            container.append(OIOPubliceret.from_json(registrering, publiceret))
        return container
