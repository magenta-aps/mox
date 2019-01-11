/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
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
public class UpdateDocumentMessage extends CreateDocumentMessage {

    protected UUID uuid;

    public static final String OPERATION = "update";

    public UpdateDocumentMessage(String authorization, String objectType, UUID uuid, JSONObject data) {
        super(authorization, objectType, data);
        this.uuid = uuid;
    }

    public UpdateDocumentMessage(String authorization, String objectType, UUID uuid, org.json.JSONObject data) {
        super(authorization, objectType, data);
        this.uuid = uuid;
    }

    public UpdateDocumentMessage(String authorization, String objectType, String uuid, JSONObject data) throws IllegalArgumentException {
        super(authorization, objectType, data);
        this.uuid = UUID.fromString(uuid);
    }

    public UpdateDocumentMessage(String authorization, String objectType, String uuid, org.json.JSONObject data) throws IllegalArgumentException {
        super(authorization, objectType, data);
        this.uuid = UUID.fromString(uuid);
    }

    @Override
    public Headers getHeaders() {
        Headers headers = super.getHeaders();
        headers.put(Message.HEADER_OBJECTID, this.uuid.toString());
        return headers;
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_UPDATE;
    }

    public static UpdateDocumentMessage parse(Headers headers, JSONObject data) {
        String operationName = headers.optString(Message.HEADER_OPERATION);
        if (UpdateDocumentMessage.OPERATION.equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(Message.HEADER_AUTHORIZATION);
            String uuid = headers.optString(Message.HEADER_MESSAGEID);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            if (uuid != null && objectType != null) {
                return new UpdateDocumentMessage(authorization, objectType, uuid, data);
            }
        }
        return null;
    }

}
