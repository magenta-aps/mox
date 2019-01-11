/*
Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.json.JSONObject;

import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public class ReadDocumentMessage extends InstanceDocumentMessage {

    public static final String OPERATION = "read";

    public ReadDocumentMessage(String authorization, String objectType, UUID uuid) {
        super(authorization, objectType, uuid);
    }

    public ReadDocumentMessage(String authorization, String objectType, String uuid) throws IllegalArgumentException {
        super(authorization, objectType, uuid);
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_READ;
    }

    public static ReadDocumentMessage parse(Headers headers, JSONObject data) throws IllegalArgumentException {
        String operationName = headers.optString(Message.HEADER_OPERATION);
        if (ReadDocumentMessage.OPERATION.equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(Message.HEADER_AUTHORIZATION);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            String uuid = headers.optString(Message.HEADER_OBJECTID);
            if (uuid != null && objectType != null) {
                return new ReadDocumentMessage(authorization, objectType, uuid);
            }
        }
        return null;
    }

}
