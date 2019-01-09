# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from amqpclient import MessageInterface, MessageSender
from amqpclient import NoSuchJob

from config import read_properties_files

from message import Message, UploadedDocumentMessage
