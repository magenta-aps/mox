package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.UploadServlet;
import dk.magenta.mox.agent.*;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.log4j.Logger;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;
import java.util.*;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;

/**
 * Created by lars on 26-11-15.
 */
@WebServlet(name = "DocumentUpload")
@MultipartConfig
public class DocumentUpload extends UploadServlet {

    private HashMap<String, SpreadsheetConverter> converterMap = new HashMap<String, SpreadsheetConverter>();
    private MessageSender moxSender;
    private Properties agentProperties;

    public void init() throws ServletException {

        ArrayList<SpreadsheetConverter> converterList = new ArrayList<SpreadsheetConverter>();
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

        Map<String, ObjectType> objectTypes = ObjectType.load(this.agentProperties);

        try {
            converterList.add(new OdfConverter(objectTypes));
            converterList.add(new XlsConverter(objectTypes));
            converterList.add(new XlsxConverter(objectTypes));
        } catch (IOException e) {
            throw new ServletException("Failed converter initialization", e);
        }
        for (SpreadsheetConverter converter : converterList) {
            for (String contentType : converter.getApplicableContentTypes()) {
                this.converterMap.put(contentType, converter);
            }
        }

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

        final String fileFieldName = "file";

        Writer output = response.getWriter();
        String authorization;
        this.tic();

        authorization = this.getSecurityToken();

        output.append("got authtoken at " + this.toc()+"\n");
        try {
            List<FileItem> files = this.getUploadFiles(request);
            for (FileItem file : files) {
                if (fileFieldName.equals(file.getFieldName())) {
                    SpreadsheetConverter converter = this.converterMap.get(file.getContentType());
                    if (converter != null) {
                        try {
                            SpreadsheetConversion conversion = converter.convert(file.getInputStream());

                            output.append("converted file " +file.getName()+ " at " + this.toc()+"\n");
                            for (String sheetName : conversion.getSheetNames()) {
                                for (String objectId : conversion.getObjectIds(sheetName)) {
                                    SpreadsheetConversion.ObjectData object = conversion.getObject(sheetName, objectId);
                                    ObjectType objectType = converter.getObjectType(object.getSheetName());
                                    String operation = object.getOperation();
                                    JSONObject data = object.convert();

                                    UUID uuid = null;
                                    try {
                                        UUID.fromString(object.getId());
                                    } catch (IllegalArgumentException e) {}

                                    output.append("extracted data for item " +file.getName()+ "/"+sheetName+"/"+objectId+" at " + this.toc()+"\n");

                                    Future<String> moxResponse = objectType.sendCommand(this.moxSender, operation, uuid, data, authorization);
                                    output.append("uploaded data for item " +file.getName()+ "/"+sheetName+"/"+objectId+" at " + this.toc()+"\n");
                                    String responseString = moxResponse.get(30, TimeUnit.SECONDS);
                                    if (responseString != null) {
                                        output.append("got response for item " + file.getName() + "/" + sheetName + "/" + objectId + " at " + this.toc() + "\n");
                                    } else {
                                        output.append("response timeout on " + file.getName() + "/" + sheetName + "/" + objectId + " at " + this.toc() + "\n");
                                    }
                                }
                            }
                        } catch (Exception e) {
                            throw new ServletException("Failed converting uploaded file", e);
                        }
                    } else {
                        throw new ServletException("No SpreadsheetConverter for content type '" + file.getContentType() + "'");
                    }

                }
            }
        } catch (FileUploadException e) {
            e.printStackTrace();
        }
    }

    private Date startTime;
    private void tic() {
        this.startTime = new Date();
    }
    private long toc() {
        return new Date().getTime() - this.startTime.getTime();
    }

    private String getSecurityToken() {
        try {
            String tokenObtainerCommand = this.agentProperties.getProperty("security.tokenObtainerCommand");
            if (tokenObtainerCommand != null) {
                Process p = Runtime.getRuntime().exec(tokenObtainerCommand);
                BufferedReader stdOut = new BufferedReader(new InputStreamReader(p.getInputStream()));

                // read the output from the command
                String line;
                while ((line = stdOut.readLine()) != null) {
                    if (line.startsWith("saml-gzipped")) {
                        return line;
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }
}
