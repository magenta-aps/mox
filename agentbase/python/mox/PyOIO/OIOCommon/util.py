# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import pytz
from datetime import datetime
from dateutil import parser


def parse_time(time_string):
    if time_string == '-infinity':
        return pytz.utc.localize(datetime.min)
    elif time_string == 'infinity':
        return pytz.utc.localize(datetime.max)
    else:
        return parser.parse(time_string)
