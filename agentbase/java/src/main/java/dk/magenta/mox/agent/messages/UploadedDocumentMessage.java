package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.json.JSONObject;

import java.lang.IllegalArgumentException;
import java.util.UUID;

/**
 * Created by lars on 22-01-16.
 */
public class UploadedDocumentMessage extends Message {

    public static final String KEY_UUID = "uuid";

    public static final String OPERATION = "upload";

    private UUID retrievalUUID;

    public UploadedDocumentMessage(UUID retrievalUUID, String authorization) {
        super(authorization);
        this.retrievalUUID = retrievalUUID;
    }

    public UploadedDocumentMessage(String retrievalUUID, String authorization) throws IllegalArgumentException {
        this(UUID.fromString(retrievalUUID), authorization);
    }

    public JSONObject getJSON() {
        JSONObject object = super.getJSON();
        object.put(KEY_UUID, this.retrievalUUID.toString());
        return object;
    }

    public static UploadedDocumentMessage parse(Headers headers, JSONObject data) {
        String operationName = headers.optString(Message.HEADER_OPERATION);
        if (UploadedDocumentMessage.OPERATION.equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(Message.HEADER_AUTHORIZATION);
            if (data != null) {
                String retrievalUUID = data.optString(KEY_UUID);
                if (retrievalUUID != null) {
                    try {
                        return new UploadedDocumentMessage(retrievalUUID, authorization);
                    } catch (IllegalArgumentException e) {
                    }
                }
            }
        }
        return null;
    }

    @Override
    public Headers getHeaders() {
        Headers headers = super.getHeaders();
        headers.put(Message.HEADER_OBJECTTYPE, HEADER_OBJECTTYPE_VALUE_DOCUMENT);
        headers.put(Message.HEADER_OPERATION, OPERATION);
        headers.put(Message.HEADER_TYPE, Message.HEADER_TYPE_VALUE_MANUAL);
        headers.put(Message.HEADER_OBJECTREFERENCE, this.retrievalUUID.toString());
        return headers;
    }
}
