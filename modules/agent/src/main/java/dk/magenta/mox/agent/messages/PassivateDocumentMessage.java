package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.json.JSONObject;

import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public class PassivateDocumentMessage extends InstanceDocumentMessage {

    protected String note = "";

    public PassivateDocumentMessage(String authorization, String objectType, UUID uuid, String note) {
        super(authorization, objectType, uuid);
        if (note == null) {
            note = "";
        }
        this.note = note;
    }

    public PassivateDocumentMessage(String authorization, String objectType, String uuid, String note) throws IllegalArgumentException {
        this(authorization, objectType, UUID.fromString(uuid), note);
    }

    public PassivateDocumentMessage(String authorization, String objectType, UUID uuid) {
        super(authorization, objectType, uuid);
    }

    public PassivateDocumentMessage(String authorization, String objectType, String uuid) throws IllegalArgumentException {
        super(authorization, objectType, uuid);
    }

    @Override
    public JSONObject getJSON() {
        JSONObject object = super.getJSON();
        object.put("Note", this.note);
        object.put("livscyklus", "Passiv");
        return object;
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_PASSIVATE;
    }

    public static PassivateDocumentMessage parse(Headers headers, JSONObject data) throws IllegalArgumentException {
        String operationName = (String) headers.get(MessageInterface.HEADER_OPERATION);
        if ("passivate".equalsIgnoreCase(operationName)) {
            String authorization = (String) headers.get(MessageInterface.HEADER_AUTHORIZATION);
            String uuid = (String) headers.get(MessageInterface.HEADER_MESSAGEID);
            String objectType = (String) headers.get(Message.HEADER_OBJECTTYPE);
            String note = null;
            if (data != null) {
                JSONObject jsonObject = new JSONObject(data);
                note = jsonObject.optString("Note");
            }
            return new PassivateDocumentMessage(authorization, objectType, uuid, note);
        }
        return null;
    }
}
