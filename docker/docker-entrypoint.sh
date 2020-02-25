#!/bin/sh

# SPDX-FileCopyrightText: 2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

################################################################################
# Changes to this file requires approval from Labs. Please add a person from   #
# Labs as required approval to your MR if you have any changes.                #
################################################################################

set -e

python3 -m oio_rest initdb --wait 30

exec "$@"
