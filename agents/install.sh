#!/bin/sh -e
# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


DIR=$(cd $(dirname $0) && pwd)

if test -n "$DOMAIN"
then
    REST_URL="https://$DOMAIN"
else
    REST_URL=https://$(hostname --fqdn)

    read -p "OIO REST URL: [$REST_URL] " -r REPLY
    echo
    if test "x$REPLY" != "x"
    then
	    REST_URL="$REPLY"
    fi
fi

. $DIR/../db/config.sh

$DIR/MoxTabel/install.py
$DIR/MoxTabel/configure.py \
    --rest-host "$REST_URL" \
    --amqp-incoming-host "$MOX_AMQP_HOST" \
    --amqp-incoming-user "$MOX_AMQP_USER" \
    --amqp-incoming-pass "$MOX_AMQP_PASS" \
    --amqp-incoming-exchange "mox.documentconvert" \
    --amqp-outgoing-host "$MOX_AMQP_HOST" \
    --amqp-outgoing-user "$MOX_AMQP_USER" \
    --amqp-outgoing-pass "$MOX_AMQP_PASS" \
    --amqp-outgoing-exchange "mox.rest"

$DIR/MoxRestFrontend/install.py
$DIR/MoxRestFrontend/configure.py \
    --rest-host "$REST_URL" \
    --amqp-host "$MOX_AMQP_HOST" \
    --amqp-user "$MOX_AMQP_USER" \
    --amqp-pass "$MOX_AMQP_PASS" \
    --amqp-exchange "mox.rest"

$DIR/MoxDocumentUpload/install.py
$DIR/MoxDocumentUpload/configure.py \
    --rest-host "$REST_URL" \
    --amqp-host "$MOX_AMQP_HOST" \
    --amqp-user "$MOX_AMQP_USER" \
    --amqp-pass "$MOX_AMQP_PASS" \
    --amqp-exchange "mox.documentconvert"

$DIR/MoxTest/install.sh

$DIR/MoxDocumentDownload/install.py
$DIR/MoxDocumentDownload/configure.py \
    --rest-host "$REST_URL"

sudo service apache2 reload
