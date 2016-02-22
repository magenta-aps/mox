package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.MessageHandler;
import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.messages.*;
import dk.magenta.mox.spreadsheet.ConvertedObject;
import dk.magenta.mox.spreadsheet.SpreadsheetConverter;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.*;
import java.util.concurrent.*;

/**
 * Created by lars on 25-01-16.
 */
public class UploadedDocumentMessageHandler implements MessageHandler {

    private MessageSender sender;
    //private Map<String, ObjectType> objectTypeMap;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);
    protected Logger log = Logger.getLogger(UploadedDocumentMessageHandler.class);


    public UploadedDocumentMessageHandler(MessageSender sender) {
        this.sender = sender;
        //this.objectTypeMap = objectTypeMap;
    }

    public Future<String> run(Headers headers, JSONObject jsonObject) {
        this.log.info("Parsing message");
        String reference = headers.get(Message.HEADER_OBJECTREFERENCE).toString();
        this.log.info("Reference: " + reference);

        String authorization = null;

        File tempFile = null;
        InputStream data = null;
        try {
            this.log.info("Retrieving data");
            URL url = new URL(reference);
            URLConnection connection = url.openConnection();
            connection.connect();
            String contentType = connection.getContentType();
            data = connection.getInputStream();
            String filename = jsonObject.optString(UploadedDocumentMessage.KEY_FILENAME);

            tempFile = File.createTempFile(filename, "tmp");
            FileOutputStream fileOutputStream = new FileOutputStream(tempFile);
            IOUtils.copy(data, fileOutputStream);
            data.close();
            fileOutputStream.close();
            this.log.info("Data retrieved ("+tempFile.length()+" bytes)");

            Map<String, Map<String, ConvertedObject>> convertedSpreadsheets = SpreadsheetConverter.convert(tempFile, contentType);
            try {
                tempFile.delete();
            } catch (SecurityException ex) {
            }

            HashMap<String, Future<String>> moxResponses = new HashMap<String, Future<String>>();
            for (String sheetName : convertedSpreadsheets.keySet()) {
                for (String objectId : convertedSpreadsheets.get(sheetName).keySet()) {
                    ConvertedObject object = convertedSpreadsheets.get(sheetName).get(objectId);
                    this.log.info("----------------------------------------");
                    this.log.info("Handling object (sheetName: "+sheetName+", objectId: "+objectId+")");
                    //ObjectType objectType = this.objectTypeMap.get(object.getSheetName());
                    String objectTypeName = object.getSheetName();
                    String operation = object.getOperation();
                    JSONObject objectData = object.getJSON();
                    UUID uuid = null;
                    try {
                        uuid = UUID.fromString(object.getId());
                    } catch (IllegalArgumentException e) {
                    }
                    this.log.info("Operation: "+operation);
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
                        this.log.info("Document message created. Sending...");
                        try {
                            Future<String> moxResponse = this.sender.send(documentMessage, true);
                            //Future<String> moxResponse = this.sender.send(objectType, operation, uuid, objectData, authorization);
                            moxResponses.put(filename + " : " + sheetName + " : " + objectId, moxResponse);
                            this.log.info("Message sent, awaiting response");
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    } else {
                        this.log.info("Failed to create a document message");
                    }
                }
            }


            final HashMap<String, Future<String>> fMoxResponses = new HashMap<String, Future<String>>(moxResponses);
            return this.pool.submit(new Callable<String>() {
                public String call() throws IOException {
                    JSONArray collectedResponses = new JSONArray();

                    for (String key : fMoxResponses.keySet()) {
                        Future<String> moxResponse = fMoxResponses.get(key);
                        try {
                            collectedResponses.put(new JSONObject(moxResponse.get(30, TimeUnit.SECONDS)));
                        } catch (InterruptedException e) {
                            //throw new ServletException("Interruption error when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                        } catch (ExecutionException e) {
                            //throw new ServletException("Execution error when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                        } catch (TimeoutException e) {
                            //throw new ServletException("Timeout (30 seconds) when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                        }
                    }
                    return collectedResponses.toString();
                }
            });


        } catch (MalformedURLException e) {
            this.log.error("Invalid url", e);
            e.printStackTrace();
        } catch (IOException e) {
            this.log.error("IOException", e);
            e.printStackTrace();
        } catch (Exception e) {
            this.log.error("General Exception", e);
            e.printStackTrace();
        }
        return null;
    }
}
