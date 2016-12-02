#!/usr/bin/env python

from PyOIO.OIOCommon.util import parse_time

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

        self.from_time = parse_time(json['from'])
        self.from_included = json.get('from_included')

        self.to_time = parse_time(json['to'])
        self.to_included = json.get('to_included')

        self.notetekst = json.get('notetekst')

        # TODO timestamps for virkning_from and virkning_to

    def in_effect(self, time):
        return self.from_time < time and time < self.to_time

    def __repr__(self):
        return 'Virkning(%s, %s)' % (self.from_time, self.to_time)

    def __str__(self):
        return 'Virkning: %s - %s' % (self.from_time, self.to_time)

    def compare_time(self, other):
        return self.from_time == other.from_time and self.to_time == other.to_time
