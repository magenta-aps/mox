package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.json.JSONObject;

import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public class UpdateDocumentMessage extends CreateDocumentMessage {

    protected UUID uuid;

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
        headers.put(MessageInterface.HEADER_MESSAGEID, this.uuid.toString());
        return headers;
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_UPDATE;
    }

    public static UpdateDocumentMessage parse(Headers headers, JSONObject data) {
        String operationName = (String) headers.get(MessageInterface.HEADER_OPERATION);
        if ("update".equalsIgnoreCase(operationName)) {
            String uuid = (String) headers.get(MessageInterface.HEADER_MESSAGEID);
            String authorization = (String) headers.get(MessageInterface.HEADER_AUTHORIZATION);
            String objectType = (String) headers.get(Message.HEADER_OBJECTTYPE);
            return new UpdateDocumentMessage(authorization, objectType, uuid, data);
        }
        return null;
    }

}
