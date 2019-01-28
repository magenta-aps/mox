#!/bin/bash -e
# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FOLDERS="modules/agent modules/json modules/spreadsheet agents/MoxTabel agents/MoxRestFrontend servlets/MoxDocumentUpload"
for FOLDER in $FOLDERS; do
    ( cd "$DIR/$FOLDER" && ./install.sh )
done
