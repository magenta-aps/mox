package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.json.JSONObject;

import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public class DeleteDocumentMessage extends PassivateDocumentMessage {

    protected String note = "";

    public DeleteDocumentMessage(String authorization, String objectType, UUID uuid, String note) {
        super(authorization, objectType, uuid, note);
    }

    public DeleteDocumentMessage(String authorization, String objectType, String uuid, String note) throws IllegalArgumentException {
        this(authorization, objectType, UUID.fromString(uuid), note);
    }

    public DeleteDocumentMessage(String authorization, String objectType, UUID uuid) {
        super(authorization, objectType, uuid);
    }

    public DeleteDocumentMessage(String authorization, String objectType, String uuid) throws IllegalArgumentException {
        super(authorization, objectType, uuid);
    }

    @Override
    public JSONObject getJSON() {
        JSONObject object = super.getJSON();
        object.put("Note", this.note);
        return object;
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_DELETE;
    }

    public static DeleteDocumentMessage parse(Headers headers, JSONObject data) throws IllegalArgumentException {
        String operationName = headers.optString(MessageInterface.HEADER_OPERATION);
        if ("delete".equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(MessageInterface.HEADER_AUTHORIZATION);
            String uuid = headers.optString(MessageInterface.HEADER_MESSAGEID);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            if (uuid != null && objectType != null) {
                String note = null;
                if (data != null) {
                    JSONObject jsonObject = new JSONObject(data);
                    note = jsonObject.optString("Note");
                }
                return new DeleteDocumentMessage(authorization, objectType, uuid, note);
            }
        }
        return null;
    }

}
