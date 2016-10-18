#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, InvalidOIOException


class ItSystem(OIOEntity):
    """It-system
    from: Specifikation af serviceinterface for Organisation. Version 1.1

    This class implements an object model reflecting the OIO It-system class.
    It contains two things only:
    - A GUID
    - A list of ItSystemRegistrering objects
    """

    def __init__(self, host, id, token=None):
        """
        Arguments:
        host:   string - the hostname of the LoRA server
        ID:     string - the GUID uniquely representing the ItSystem
        """
        super(ItSystem, self).__init__(host, id, token)

        if 'registreringer' not in self.json or len(self.json.get('registreringer')) == 0:
            raise InvalidOIOException("Item %s has no registreringer" % id)

        self.registreringer = []
        for registrering in self.json['registreringer']:
            self.registreringer.append(ItSystemRegistrering(registrering))

        first_registrering = self.registreringer[0]
        system_properties = first_registrering.itsystemegenskaber[0]
        self.brugervendtnoegle = system_properties.brugervendtnoegle
        self.navn = system_properties.itsystemnavn

    def __repr__(self):
        # TODO not ideal, but don't think more is pragmatically needed
        return "ItSystem(%s)" % self.id

    def __str__(self):
        return "ItSystem: %s" % self.id

    def get_path(self):
        return "/organisation/itsystem/%s" % self.id


class ItSystemRegistrering(object):
    """It-system registrering
    from: Specifikation af serviceinterface for Organisation. Version 1.1

    This class implements a Python object model reflecting the above for the
    It-system registreringclass. The meat of data about an It system is
    contained in these.

    The ItSystem class will contain a list of 1..N of these.

    """

    def __init__(self, data):
        """
        Arguments:
        data: OIO JSON formatted text containing one Registrering
        """

        self.json = data
        self.note = self.json.get('note')
        self.attributter = {}
        self.attributter['itsystemegenskaber'] = self._populate_egenskaber(
            self.json['attributter']['itsystemegenskaber']
        )
        self.tilstande = {}
        self.tilstande['itsystemgyldighed'] = self._populate_gyldighed(
            self.json['tilstande']['itsystemgyldighed']
        )
        self.relationer = self._populate_relationer(self.json['relationer'])

    @property
    def itsystemegenskaber(self):
        return self.attributter['itsystemegenskaber']

    @property
    def itsystemgyldighed(self):
        return self.tilstande['itsystemgyldighed']

    def _populate_relationer(self, data):
        relationer = {}
        types = ['tilhoerer', 'tilknyttedeorganisationer', 'tilknyttedeenheder',
                 'tilknyttedefunktioner', 'tilknyttedeinteressefaelleskaber',
                 'tilknyttedeitsystemer', 'tilknyttedebrugere',
                 'tilknyttedepersoner', 'opgaver', 'systemtyper', 'adresser']
        for type in types:
            if type in data:
                relationer[type] = []
                for relation in data[type]:
                    r = {}
                    r['uuid'] = relation['uuid']
                    r['virkning'] = Virkning(relation['virkning'])
                    relationer[type].append(r)
        return relationer


    def _populate_egenskaber(self, data):
        egenskaber = []
        for egenskab in data:
            egenskaber.append(ItSystemEgenskab(egenskab))
        return egenskaber

    def _populate_gyldighed(self, g_data):
        g_list = []
        for gyldighed in g_data:
            g_list.append(ItSystemGyldighed(gyldighed))
        return g_list

    def __repr__(self):
        # TODO probably don't use this, bound to be ugly
        return "ItSystemRegistrering(%s)" % self.json

    def __str__(self):
        # TODO find better way of identifying the registrering
        # TODO bad assummption that brugervendtnoegle is unique
        key = self.attributter['itsystemegenskaber'][0].brugervendtnoegle
        return "ItSystemRegistrering: %s" % key


class ItSystemEgenskab(object):

    def __init__(self, data):
        self.brugervendtnoegle = data['brugervendtnoegle']
        self.itsystemnavn = data.get('itsystemnavn')
        self.itsystemtype = data.get('itsystemtype')
        self.konfigurationreference = data.get('konfigurationreference')
        self.virkning = Virkning(data['virkning'])


class ItSystemGyldighed(object):

    def __init__(self, data):
        gyldige_tilstande = ['Aktiv', 'Inaktiv']
        if data['gyldighed'] in gyldige_tilstande:
            self.gyldighed = data['gyldighed']
        else:
            raise InvalidOIOException('Invalid gyldighed "%s"' % data['gyldighed'])
        self.virkning = Virkning(data['virkning'])

