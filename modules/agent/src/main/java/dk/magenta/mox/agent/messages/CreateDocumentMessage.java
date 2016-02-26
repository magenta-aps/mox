package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.json.JSONObject;

/**
 * Created by lars on 15-02-16.
 */
public class CreateDocumentMessage extends DocumentMessage {

    protected JSONObject data;

    public CreateDocumentMessage(String authorization, String objectType, JSONObject data) {
        super(authorization, objectType);
        this.data = data;
    }

    public CreateDocumentMessage(String authorization, String objectType, org.json.JSONObject data) {
        super(authorization, objectType);
        this.data = new JSONObject(data);
    }

    @Override
    public JSONObject getJSON() {
        return this.data;
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_CREATE;
    }

    public static CreateDocumentMessage parse(Headers headers, JSONObject data) {
        String operationName = headers.optString(MessageInterface.HEADER_OPERATION);
        if ("create".equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(MessageInterface.HEADER_AUTHORIZATION);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            if (objectType != null) {
                return new CreateDocumentMessage(authorization, objectType, data);
            }
        }
        return null;
    }
}
