package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.json.JSONObject;

/**
 * Created by lars on 15-02-16.
 */
public class CreateDocumentMessage extends DocumentMessage {

    protected JSONObject data;

    public static final String OPERATION = "create";

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
        String operationName = headers.optString(Message.HEADER_OPERATION);
        if (CreateDocumentMessage.OPERATION.equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(Message.HEADER_AUTHORIZATION);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            if (objectType != null) {
                return new CreateDocumentMessage(authorization, objectType, data);
            }
        }
        return null;
    }
}
