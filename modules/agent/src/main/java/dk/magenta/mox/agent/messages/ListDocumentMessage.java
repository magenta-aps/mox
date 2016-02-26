package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.agent.ParameterMap;
import dk.magenta.mox.json.JSONObject;
import org.json.JSONArray;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Created by lars on 15-02-16.
 */
public class ListDocumentMessage extends DocumentMessage {

    protected ArrayList<UUID> uuids;

    public ListDocumentMessage(String authorization, String objectType, List<UUID> uuids) {
        super(authorization, objectType);
        this.uuids = new ArrayList<>(uuids);
    }

    public ListDocumentMessage(String authorization, String objectType, UUID uuid) {
        super(authorization, objectType);
        this.uuids = new ArrayList<>(uuids);
        this.uuids.add(uuid);
    }

    @Override
    public JSONObject getJSON() {
        JSONObject object = super.getJSON();
        JSONArray uuidList = new JSONArray();
        for (UUID uuid : uuids) {
            uuidList.put(uuid.toString());
        }
        object.put("query", uuidList);
        return object;
    }

    @Override
    protected String getOperationName() {
        return DocumentMessage.OPERATION_LIST;
    }

    public static ListDocumentMessage parse(Headers headers, JSONObject data) {
        String operationName = headers.optString(MessageInterface.HEADER_OPERATION);
        if ("list".equalsIgnoreCase(operationName)) {
            String authorization = headers.optString(MessageInterface.HEADER_AUTHORIZATION);
            String objectType = headers.optString(Message.HEADER_OBJECTTYPE);
            if (objectType != null) {
                ArrayList<UUID> uuids = new ArrayList<>();
                if (data != null) {
                    JSONObject jsonObject = new JSONObject(data);
                    JSONArray uuidList = jsonObject.optJSONArray("query");
                    for (int i = 0; i < uuidList.length(); i++) {
                        uuids.add(UUID.fromString(uuidList.getString(i)));
                    }
                }
                return new ListDocumentMessage(authorization, objectType, uuids);
            }
        }
        return null;
    }
}
