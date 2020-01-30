#!/bin/bash -e
# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FOLDERS="modules/agent modules/json modules/spreadsheet agents/MoxTabel agents/MoxRestFrontend servlets/MoxDocumentUpload"
for FOLDER in $FOLDERS; do
    ( cd "$DIR/$FOLDER" && ./install.sh )
done
