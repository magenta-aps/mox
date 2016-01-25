package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.MessageHandler;
import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.ObjectType;
import dk.magenta.mox.agent.messages.Headers;
import dk.magenta.mox.agent.messages.Message;
import dk.magenta.mox.spreadsheet.ConvertedObject;
import dk.magenta.mox.spreadsheet.SpreadsheetConverter;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.naming.OperationNotSupportedException;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
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
        String reference = (String) headers.get(Message.HEADER_OBJECTREFERENCE);

        String authorization = null;

        try {
            URL url = new URL(reference);
            InputStream data = url.openConnection().getInputStream();
            String filename = "noget";
            String contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            SpreadsheetConverter.convert(data, contentType);

            Map<String, Map<String, ConvertedObject>> convertedSpreadsheets = SpreadsheetConverter.convert(data, contentType);

            HashMap<String, Future<String>> moxResponses = new HashMap<String, Future<String>>();
            for (String sheetName : convertedSpreadsheets.keySet()) {
                for (String objectId : convertedSpreadsheets.get(sheetName).keySet()) {
                    ConvertedObject object = convertedSpreadsheets.get(sheetName).get(objectId);

                    ObjectType objectType = this.objectTypeMap.get(object.getSheetName());
                    String operation = object.getOperation();
                    JSONObject objectData = object.getJSON();

                    UUID uuid = null;
                    try {
                        uuid = UUID.fromString(object.getId());
                    } catch (IllegalArgumentException e) {
                    }

                    try {
                        Future<String> moxResponse = this.sender.send(objectType, operation, uuid, objectData, authorization);
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
