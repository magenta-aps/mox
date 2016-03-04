package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.MessageHandler;
import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.ObjectType;
import dk.magenta.mox.agent.messages.Headers;
import dk.magenta.mox.agent.messages.Message;
import dk.magenta.mox.agent.messages.UploadedDocumentMessage;
import dk.magenta.mox.spreadsheet.ConvertedObject;
import dk.magenta.mox.spreadsheet.SpreadsheetConverter;
import org.apache.commons.io.IOUtils;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.naming.OperationNotSupportedException;
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
    private Map<String, ObjectType> objectTypeMap;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);


    public UploadedDocumentMessageHandler(MessageSender sender, Map<String, ObjectType> objectTypeMap) {
        this.sender = sender;
        this.objectTypeMap = objectTypeMap;
    }

    public Future<String> run(Headers headers, JSONObject jsonObject) {
        System.out.println("Reading a message " + headers.toString()+" -- "+jsonObject.toString());
        String reference = headers.get(Message.HEADER_OBJECTREFERENCE).toString();

        String authorization = null;

        File tempFile = null;
        InputStream data = null;
        try {
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

            Map<String, Map<String, ConvertedObject>> convertedSpreadsheets = SpreadsheetConverter.convert(tempFile, contentType);
            try {
                tempFile.delete();
            } catch (SecurityException ex) {
            }

            HashMap<String, Future<String>> moxResponses = new HashMap<String, Future<String>>();
            for (String sheetName : convertedSpreadsheets.keySet()) {
                for (String objectId : convertedSpreadsheets.get(sheetName).keySet()) {
                    ConvertedObject object = convertedSpreadsheets.get(sheetName).get(objectId);

                    ObjectType objectType = this.objectTypeMap.get(object.getSheetName());
                    String operation = object.getOperation();
                    JSONObject objectData = object.getJSON();
                    System.out.println("found command "+operation+" "+objectType.getName()+" "+objectData.toString());

                    UUID uuid = null;
                    try {
                        uuid = UUID.fromString(object.getId());
                    } catch (IllegalArgumentException e) {
                    }

                    try {
                        Future<String> moxResponse = this.sender.send(objectType, operation, uuid, objectData, authorization);
                        System.out.println(operation + " " + objectType.getName()+" "+objectData.toString());
                        moxResponses.put(filename + " : " + sheetName + " : " + objectId, moxResponse);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    } catch (OperationNotSupportedException e) {
                        e.printStackTrace();
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
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
