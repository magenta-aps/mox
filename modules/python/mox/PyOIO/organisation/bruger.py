#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity


class Bruger(OIOEntity):
    """Represents the OIO information model 1.1 Bruger
    https://digitaliser.dk/resource/991439

    """

    def __init__(self, host, id, token=None):
        """ Args:
        host:   string - the hostname of the LoRA server
        ID:     string - the GUID uniquely representing the Bruger
        """
        super(Bruger, self).__init__(host, id, token)
        self.registreringer = self._populate_registreringer()

    def _populate_registreringer(self):
        registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            brugerregistrering = BrugerRegistrering(self.id, index, registrering)
            registreringer.append(brugerregistrering)
        return registreringer

    def __repr__(self):
        return 'Bruger("%s", "%s"")' % (self.host, self.id)

    def __str__(self):
        return 'Bruger: %s' % self.id

    def get_path(self):
        return "/organisation/bruger/%s" % self.id

    @property
    def brugervendtnoegle(self):
        for registrering in self.registreringer:
            for egenskab in registrering.attributter.brugeregenskaber:
                if hasattr(egenskab, 'brugervendtnoegle'):
                    return egenskab['brugervendtnoegle']


class BrugerRegistrering(object):

    def __init__(self, ID, registrering_number, json):
        # TODO fratidspunkt
        # TODO Relationer
        self.id = ID # which user is this registrering about
        self.json = json
        self.registrering_number = registrering_number
        self.attributter = self._populate_attributter(self.json['attributter'])
        self.livscykluskode = self.json['livscykluskode']
        self.note = self.json.get('note')
        self.tilstande = self._populate_brugergyldighed(self.json['tilstande'])

    def _populate_brugergyldighed(self, json):
        brugergyldigheder = []
        for brugergyldighed in json['brugergyldighed']:
            brugergyldigheder.append(BrugerGyldighed(self.id, brugergyldighed))
        return brugergyldigheder

    def _populate_attributter(self, json):
        attributter = BrugerAttributListe(self.id, json)
        return attributter

    def __repr__(self):
        return 'BrugerRegistrering("%s", %s)' % (self.id, self.registrering_number)

    def __str__(self):
        return 'BrugerRegistrering: Bruger "%s", Nr. %s' % (self.id, self.registrering_number)


class BrugerAttributListe(object):
    """ Container for a list of 1..* BrugerEgenskaber objects.
    There should be exactly one of these objects per BrugerRegistrering

    Args:
    ID: string - Bruger GUID
    json: the relevant json data

    """

    def __init__(self, id, json):
        self.id = id
        self.json = json
        self.brugeregenskaber = self._populate_brugeregenskaber(self.json)

    def _populate_brugeregenskaber(self, json):
        # TODO must be minimum 1 brugeregenskab; 1..*
        brugeregenskaber = []
        for brugeregenskab in json['brugeregenskaber']:
            brugeregenskaber.append(BrugerEgenskaber(brugeregenskab))
        return brugeregenskaber

    def __repr__(self):
        return 'BrugerAttributListe("%s")' % (self.id)

    def __str__(self):
        return 'BrugerAttributListe: Bruger "%s"' % (self.id)


class BrugerGyldighed(object):
    """ Glorified dictionary with two elements: a Virkning object and
    a Status limited to Aktiv and Inaktiv

    Args:
    ID: string - Bruger GUID
    json: the relevant json data
    """

    def __init__(self, id, json):
        self.id = id
        self.json = json
        if self.json['gyldighed'] in ['Aktiv', 'Inaktiv']:
            self.gyldighed = self.json['gyldighed']
        else:
            # TODO throw a descriptive error
            self.gyldighed = "ERROR"
        self.virkning = Virkning(self.json['virkning'])


class BrugerEgenskaber(object):
    """Direct properties of the Bruger in question."""

    def __init__(self, json):
        """Args:
        json: the dictionary directly under the 'attributter' entry
        """
        self.brugernavn = json['brugernavn'] # 0..1
        self.brugervendtnoegle = json['brugervendtnoegle'] # 0..1
        self.virkning = Virkning(json['virkning'])
        self.brugertype = json.get('brugertype')

    def __repr__(self):
        return 'BrugerEgenskaber("%s", "%s")' % (self.brugernavn, self.brugervendtnoegle)

    def __str__(self):
        return 'BrugerEgenskaber: Bruger "%s" - "%s"' % (self.brugernavn, self.brugervendtnoegle)

