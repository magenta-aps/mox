/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.agent.messages;


import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public abstract class InstanceDocumentMessage extends DocumentMessage {

    protected UUID uuid;

    public InstanceDocumentMessage(String authorization, String objectType, UUID uuid) {
        super(authorization, objectType);
        this.uuid = uuid;
    }

    public InstanceDocumentMessage(String authorization, String objectType, String uuid) throws IllegalArgumentException {
        this(authorization, objectType, UUID.fromString(uuid));
    }

    public Headers getHeaders() {
        Headers headers = super.getHeaders();
        headers.put(Message.HEADER_OBJECTID, this.uuid.toString());
        return headers;
    }
}
