package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.json.JSONObject;

import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public class ReadDocumentMessage extends InstanceDocumentMessage {

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
        String operationName = headers.optString(MessageInterface.HEADER_OPERATION);
        if ("read".equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(MessageInterface.HEADER_AUTHORIZATION);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            String uuid = headers.optString(MessageInterface.HEADER_MESSAGEID);
            if (uuid != null && objectType != null) {
                return new ReadDocumentMessage(authorization, objectType, uuid);
            }
        }
        return null;
    }

}
