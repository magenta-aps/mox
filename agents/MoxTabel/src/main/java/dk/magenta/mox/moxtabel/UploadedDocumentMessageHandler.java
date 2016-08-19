package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.MessageHandler;
import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.exceptions.MissingHeaderException;
import dk.magenta.mox.agent.messages.*;
import dk.magenta.mox.agent.rest.RestClient;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.json.JSONObject;

import java.io.*;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.*;
import java.util.concurrent.*;

/**
 * Created by lars on 25-01-16.
 */
public class UploadedDocumentMessageHandler implements MessageHandler {

    private RestClient restClient;
    private MessageSender sender;
    //private Map<String, ObjectType> objectTypeMap;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);
    protected Logger log = Logger.getLogger(UploadedDocumentMessageHandler.class);

    public UploadedDocumentMessageHandler(MessageSender sender, URL restInterface) throws MalformedURLException {
        this.sender = sender;
        this.restClient = new RestClient(restInterface);
    }

    /**
     * Simple representation of an OIO document.
     * It assumes a document that has only one variant/part.
     */
    public class SimpleOIODocument {
        private String title;
        private URI content;
        private String contentType;

        public SimpleOIODocument(String title, URI content, String
                contentType) {
            this.title = title;
            this.content = content;
            this.contentType = contentType;
        }

        public String getContentType() {
            return contentType;
        }

        public URI getContent() {
            return content;
        }

        public String getTitle() {
            return title;
        }
    }

    private class MessageRequest {
        public DocumentMessage documentMessage;
        public String identifier;
        public Future<String> response;
        public MessageRequest(String identifier, DocumentMessage documentMessage) {
            this.identifier = identifier;
            this.documentMessage = documentMessage;
        }
    }

    /**
     * Return a simple representation of an OIO document given its UUID.
     *
     * Assumes that the document contains only one variant and part, and
     * makes no assumptions about the name of the variant/part.
     *
     * @param uuid
     * @param authorization
     * @return
     * @throws IOException
     */
    protected SimpleOIODocument fetchDocumentByUUID(UUID uuid,
                                                    String authorization) throws IOException {

        String response = restClient.rest("GET", "/dokument/dokument/" + uuid.toString(), null,
                authorization);
        JSONObject jsonObject = new JSONObject(response);

        try {
            JSONObject registration = jsonObject.getJSONArray(uuid.toString()).getJSONObject(0).getJSONArray("registreringer").getJSONObject(0);
            JSONObject properties = registration.getJSONObject("attributter").getJSONArray("dokumentegenskaber").getJSONObject(0);
            JSONObject partProperties = registration.getJSONArray("varianter")
                    .getJSONObject(0).getJSONArray("dele").getJSONObject(0)
                    .getJSONArray("egenskaber").getJSONObject(0);

            // Grab the important metadata about the document
            URI content = new URI(partProperties.getString("indhold"));
            String contentType = partProperties.getString("mimetype");
            String title = properties.getString("titel");

            return new SimpleOIODocument(title, content, contentType);
        } catch (NullPointerException e) {
            throw new RuntimeException("Error parsing document response", e);
        } catch (URISyntaxException e) {
            throw new RuntimeException("Invalid URI in 'indhold' attribute " +
                    "of document.", e);
        }
    }

    @Override
    public Future<String> run(Headers headers, JSONObject jsonObject) {
        this.log.info("Parsing message");
        try {
            UUID reference = UUID.fromString(headers.getString(Message.HEADER_OBJECTREFERENCE));
            this.log.info("Reference: " + reference);

            String authorization = headers.getString(Message.HEADER_AUTHORIZATION);
            this.log.info("Got authorization");

            // Fetch document metadata
            this.log.info("Retrieving document metadata");
            SimpleOIODocument simpleOIODocument = fetchDocumentByUUID
                    (reference, authorization);
            URI content = simpleOIODocument.getContent();
            String contentType = simpleOIODocument.getContentType();
            String title = simpleOIODocument.getTitle();
            String contentPath = content.getSchemeSpecificPart();

            // Download document
            this.log.info("Retrieving document contents");
            InputStream data = restClient.restRawResponse("GET",
                    "/dokument/dokument/" + contentPath, null, authorization);

            // Save it to a temp file.
            File tempFile = File.createTempFile("tmp", ".temp");
            FileOutputStream fileOutputStream = new FileOutputStream(tempFile);
            IOUtils.copy(data, fileOutputStream);
            data.close();
            fileOutputStream.close();
            this.log.info("Contents retrieved (" + tempFile.length() + " bytes)");

            Map<String, Map<String, List<ConvertedObject>>> convertedSpreadsheets = SpreadsheetConverter.convert(tempFile, contentType);
            try {
                tempFile.delete();
            } catch (SecurityException ex) {
            }

            ArrayList<ArrayList<MessageRequest>> chains = new ArrayList<>();
            int longestChainLength = 0;

            for (String sheetName : convertedSpreadsheets.keySet()) {
                for (String objectId : convertedSpreadsheets.get(sheetName).keySet()) {
                    List<ConvertedObject> objects = convertedSpreadsheets.get(sheetName).get(objectId);
                    int i = 0;
                    ArrayList<MessageRequest> currentChain = new ArrayList<>();
                    for (ConvertedObject object : objects) {
                        i++;
                        this.log.info("----------------------------------------");
                        this.log.info("Handling object (sheetName: " + sheetName + ", objectId: " + objectId + " #" + i + ")");
                        String objectTypeName = object.getSheetName();
                        String operation = object.getOperation();
                        JSONObject objectData = object.getJSON();
                        UUID uuid = null;
                        try {
                            uuid = UUID.fromString(object.getId());
                        } catch (IllegalArgumentException e) {
                        }
                        this.log.info("Operation: " + operation);
                        this.log.info("UUID: " + ((uuid == null) ? null : uuid.toString()));

                        DocumentMessage documentMessage = null;
                        switch (operation.trim().toLowerCase()) {
                            case DocumentMessage.OPERATION_READ:
                                documentMessage = new ReadDocumentMessage(authorization, objectTypeName, uuid);
                                break;
                            case DocumentMessage.OPERATION_LIST:
                                documentMessage = new ListDocumentMessage(authorization, objectTypeName, uuid);
                                break;
                            case DocumentMessage.OPERATION_CREATE:
                                documentMessage = new CreateDocumentMessage(authorization, objectTypeName, objectData);
                                break;
                            case DocumentMessage.OPERATION_UPDATE:
                                documentMessage = new UpdateDocumentMessage(authorization, objectTypeName, uuid, objectData);
                                break;
                            case DocumentMessage.OPERATION_PASSIVATE:
                                documentMessage = new PassivateDocumentMessage(authorization, objectTypeName, uuid);
                                break;
                            case DocumentMessage.OPERATION_DELETE:
                                documentMessage = new DeleteDocumentMessage(authorization, objectTypeName, uuid);
                                break;
                        }
                        if (documentMessage != null) {
                            String identifier = reference + " : " + title + " : " + operation.trim().toLowerCase() + " : " + objectId;
                            currentChain.add(new MessageRequest(identifier, documentMessage));
                        }
                    }
                    if (!currentChain.isEmpty()) {
                        chains.add(currentChain);
                        if (currentChain.size() > longestChainLength) {
                            longestChainLength = currentChain.size();
                        }
                    }
                }
            }

            ArrayList<MessageRequest> requests = new ArrayList<>();
            for (int i=0; i<longestChainLength; i++) {
                ArrayList<MessageRequest> waitees = new ArrayList<>();
                for (List<MessageRequest> chain : chains) {
                    if (!chain.isEmpty()) {
                        MessageRequest request = chain.remove(0);
                        try {
                            Future<String> moxResponse = this.sender.send(request.documentMessage, true);
                            request.response = moxResponse;
                            // moxResponses.put(request.identifier, moxResponse);
                            requests.add(request);
                            if (!chain.isEmpty()) {
                                waitees.add(request);
                            }
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                }
                if (!waitees.isEmpty()) {
                    this.log.info("Waiting for "+waitees.size()+" responses");
                    for (MessageRequest waitee : waitees) {
                        if (waitee.response != null) {
                            waitee.response.get(60, TimeUnit.SECONDS);
                        }
                    }
                }
            }

            //final HashMap<String, Future<String>> fMoxResponses = new HashMap<String, Future<String>>(moxResponses);
            final List<MessageRequest> fRequests = new ArrayList<>(requests);
            return this.pool.submit(new Callable<String>() {
                public String call() throws IOException {
                    JSONObject collectedResponses = new JSONObject();

                    for (MessageRequest messageRequest : fRequests) {
                        try {
                            String realResponse = messageRequest.response.get(60, TimeUnit.SECONDS);
                            collectedResponses.put(messageRequest.identifier, new JSONObject(realResponse));
                            // UploadedDocumentMessageHandler.this.log.info(messageRequest.identifier+" --- "+realResponse);
                            if (realResponse.contains("Got error response")) {
                                UploadedDocumentMessageHandler.this.log.info("Failed " + messageRequest.identifier + " / " + realResponse);
                            } else {
                                UploadedDocumentMessageHandler.this.log.info("Successful "+messageRequest.identifier + " / " + realResponse);
                            }
                        } catch (InterruptedException | ExecutionException | TimeoutException e) {
                            UploadedDocumentMessageHandler.this.log.info("Response failed: "+ e.getMessage());
                            //throw new ServletException("Interruption error when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                        }
                    }
                    UploadedDocumentMessageHandler.this.log.info("Returning collected responses");
                    return collectedResponses.toString(2);
                }
            });

        } catch (MalformedURLException e) {
            this.log.error("Invalid url", e);
            e.printStackTrace();
        } catch (IOException e) {
            this.log.error("IOException", e);
            e.printStackTrace();
        } catch (MissingHeaderException e) {
            this.log.error("Missing header in message", e);
        } catch (Exception e) {
            this.log.error("General Exception", e);
            e.printStackTrace();
        }
        return null;
    }
}
