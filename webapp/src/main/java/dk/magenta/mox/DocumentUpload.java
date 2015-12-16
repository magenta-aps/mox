package dk.magenta.mox;

import dk.magenta.mox.agent.*;
import dk.magenta.mox.json.JSONObject;
import dk.magenta.mox.spreadsheet.ConvertedObject;
import dk.magenta.mox.spreadsheet.SpreadsheetConverter;
import org.apache.log4j.Logger;

import javax.naming.OperationNotSupportedException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 26-11-15.
 */
@WebServlet(name = "DocumentUpload")
@MultipartConfig
public class DocumentUpload extends UploadServlet {

    private MessageSender moxSender;
    private Properties agentProperties;
    private Map<String, ObjectType> objectTypes;

    public void init() throws ServletException {

        this.agentProperties = new Properties();
        try {
            this.agentProperties.load(this.getServletContext().getResourceAsStream("/WEB-INF/agent.properties"));
        } catch (IOException e) {
            throw new ServletException("Failed to load /WEB-INF/agent.properties",e);
        }
        String queueInterface = this.getPropertyOrThrow(this.agentProperties, "amqp.interface");
        String queueName = this.getPropertyOrThrow(this.agentProperties, "amqp.queue");
        String queueUsername = this.getPropertyOrThrow(this.agentProperties, "amqp.username");
        String queuePassword = this.getPropertyOrThrow(this.agentProperties, "amqp.password");

        this.objectTypes = ObjectType.load(this.agentProperties);

        try {
            this.moxSender = new MessageSender(queueUsername, queuePassword, queueInterface, null, queueName);
        } catch (IOException e) {
            throw new ServletException("Unable to connect to amqp queue '"+queueInterface+"/"+queueName+"'. Documents were not dispatched.", e);
        } catch (TimeoutException e) {
            throw new ServletException("Timeout when connecting to amqp queue '"+queueInterface+"/"+queueName+"'. Documents were not dispatched.", e);
        }
    }

    private String getPropertyOrThrow(Properties properties, String key) throws ServletException {
        String value = properties.getProperty(key);
        if (value == null) {
            throw new ServletException("Failed to get property '"+key+"' from configuration file");
        }
        return value;
    }


    Logger log = Logger.getLogger(DocumentUpload.class);

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        try {
            Writer output = response.getWriter();

            String authorization = request.getHeader("authorization");
            if (authorization == null) {
                authorization = request.getParameter("authtoken");
            }

            List<UploadedFile> files = this.getUploadFiles(request);

            HashMap<String, Future<String>> moxResponses = new HashMap<String, Future<String>>();
            for (UploadedFile file : files) {

                Map<String, Map<String, ConvertedObject>> convertedSpreadsheets;
                try {
                    convertedSpreadsheets = SpreadsheetConverter.convert(file.getInputStream(), file.getContentType());
                } catch (Exception e) {
                    throw new ServletException("Failed converting uploaded file", e);
                }
                for (String sheetName : convertedSpreadsheets.keySet()) {
                    for (String objectId : convertedSpreadsheets.get(sheetName).keySet()) {
                        ConvertedObject object = convertedSpreadsheets.get(sheetName).get(objectId);

                        ObjectType objectType = this.objectTypes.get(object.getSheetName());
                        String operation = object.getOperation();
                        JSONObject data = object.getJSON();

                        UUID uuid = null;
                        try {
                            uuid = UUID.fromString(object.getId());
                        } catch (IllegalArgumentException e) {
                        }

                        try {
                            Future<String> moxResponse = this.moxSender.send(objectType, operation, uuid, data, authorization);
                            moxResponses.put(file.getFilename() + " : " + sheetName + " : " + objectId, moxResponse);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        } catch (OperationNotSupportedException e) {
                            e.printStackTrace();
                        }

                    }
                }

            }

            for (String key : moxResponses.keySet()) {
                Future<String> moxResponse = moxResponses.get(key);
                String responseString;
                try {
                    responseString = moxResponse.get(30, TimeUnit.SECONDS);
                } catch (InterruptedException e) {
                    throw new ServletException("Interruption error when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                } catch (ExecutionException e) {
                    throw new ServletException("Execution error when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                } catch (TimeoutException e) {
                    throw new ServletException("Timeout (30 seconds) when interfacing with rest interface through message queue.\nWhen uploading " + key, e);
                }
                if (responseString != null) {
                    JSONObject responseObject = new JSONObject(responseString);
                    if (responseObject != null) {
                        String errorType = responseObject.optString("type");
                        if (errorType != null && errorType.equalsIgnoreCase("ExecutionException")) {
                            throw new ServletException("Error from REST interface: " + responseObject.optString("message", responseString) + "\nWhen uploading " + key);
                        }
                    }

                    output.append(key + " => " + responseString);

                } else {
                    throw new ServletException("No response from REST interface\nWhen uploading " + key);
                }
            }
        } catch (ServletException e) {
            log.error("Error when receiving or parsing upload", e);
            throw e;
        }

    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Writer output = response.getWriter();
        output.append("<html>\n");
        output.append("<head>\n");
        output.append("<title>Mox document uploader</title>\n");
        output.append("</head>\n");
        output.append("<body>\n");
        output.append("<form action=\"DocumentUpload\" method=\"POST\" enctype=\"multipart/form-data\">\n");
        output.append("<input type=\"file\" name=\"file\"/><br/>\n");
        output.append("<textarea name=\"authtoken\"></textarea><br/>\n");
        output.append("<input type=\"submit\"/>\n");
        output.append("</form>\n");
        output.append("</body>\n");
        output.append("</html>\n");
    }

}
