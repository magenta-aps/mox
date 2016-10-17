#!/usr/bin/env python

class Virkning(object):
    """ Virkning is a fairly broadly used class. Its purpose when attached to
    metadata is to lend the metadata bitemporality.
    """

    def __init__(self, json):
        """Args:

        json: (dictionary) data containing the attributes of the Virkning object
        """
        # TODO below might need to live with missing elements?
        self.aktoerref = json.get('aktoerref')
        self.aktoertypekode = json.get('aktoertypekode')

        self.virkning_from = json['from']
        self.virkning_from_included = json.get('from_included')

        self.virkning_to = json['to']
        self.virkning_to_included = json.get('to_included')

        self.notetekst = json.get('notetekst')

        # TODO timestamps for virkning_from and virkning_to

    def __repr__(self):
        return 'Virkning(%s, %s)' % (self.virkning_from, self.virkning_to)

    def __str__(self):
        return 'Virkning: %s - %s' % (self.virkning_from, self.virkning_to)
