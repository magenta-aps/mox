package dk.magenta.mox.agent.messages;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by lars on 25-01-16.
 */
public class DocumentMessage extends Message {

    public static final String HEADER_OBJECTTYPE_VALUE_DOCUMENT = "dokument";

    public DocumentMessage(String authorization) {
        super(authorization);
    }

    public Headers getHeaders() {
        Headers headers = super.getHeaders();
        headers.put(Message.HEADER_OBJECTTYPE, HEADER_OBJECTTYPE_VALUE_DOCUMENT);
        return headers;
    }
}
