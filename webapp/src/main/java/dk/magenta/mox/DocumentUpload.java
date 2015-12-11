package dk.magenta.mox;

import dk.magenta.mox.agent.*;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.log4j.Logger;
import org.json.JSONObject;

import javax.net.ssl.HttpsURLConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.*;
import java.util.concurrent.Future;
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
    private String restInterface;

    private static Collection<String> getResources(
            final String element,
            final Pattern pattern){
        final ArrayList<String> retval = new ArrayList<String>();
        final File file = new File(element);
        if(file.isDirectory()){
            retval.addAll(getResourcesFromDirectory(file, pattern));
        } else{
            retval.addAll(getResourcesFromJarFile(file, pattern));
        }
        return retval;
    }

    private static Collection<String> getResourcesFromJarFile(
            final File file,
            final Pattern pattern){
        final ArrayList<String> retval = new ArrayList<String>();
        ZipFile zf;
        try{
            zf = new ZipFile(file);
        } catch(final ZipException e){
            throw new Error(e);
        } catch(final IOException e){
            throw new Error(e);
        }
        final Enumeration e = zf.entries();
        while(e.hasMoreElements()){
            final ZipEntry ze = (ZipEntry) e.nextElement();
            final String fileName = ze.getName();
            final boolean accept = true;//pattern.matcher(fileName).matches();
            if(accept){
                retval.add(fileName);
            }
        }
        try{
            zf.close();
        } catch(final IOException e1){
            throw new Error(e1);
        }
        return retval;
    }

    private static Collection<String> getResourcesFromDirectory(
            final File directory,
            final Pattern pattern){
        final ArrayList<String> retval = new ArrayList<String>();
        final File[] fileList = directory.listFiles();
        for(final File file : fileList){
            if(file.isDirectory()){
                retval.addAll(getResourcesFromDirectory(file, pattern));
            } else{
                try{
                    final String fileName = file.getCanonicalPath();
                    final boolean accept = true;//pattern.matcher(fileName).matches();
                    if(accept){
                        retval.add(fileName);
                    }
                } catch(final IOException e){
                    throw new Error(e);
                }
            }
        }
        return retval;
    }

    private void unpackResource(String resourceName) {
        Thread.currentThread().getContextClassLoader().getResourceAsStream(resourceName);

    }

    public void init() throws ServletException {

        ArrayList<SpreadsheetConverter> converterList = new ArrayList<SpreadsheetConverter>();
        Properties agentProperties = new Properties();
        try {
            agentProperties.load(this.getServletContext().getResourceAsStream("/WEB-INF/agent.properties"));
        } catch (IOException e) {
            throw new ServletException("Failed to load /WEB-INF/agent.properties",e);
        }
        String queueInterface = this.getPropertyOrThrow(agentProperties, "amqp.interface");
        String queueName = this.getPropertyOrThrow(agentProperties, "amqp.queue");
        String queueUsername = this.getPropertyOrThrow(agentProperties, "amqp.username");
        String queuePassword = this.getPropertyOrThrow(agentProperties, "amqp.password");

        Map<String, ObjectType> objectTypes = ObjectType.load(agentProperties);

        this.restInterface = this.getPropertyOrThrow(agentProperties, "rest.interface");

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

        authorization = this.getSecurityToken();



        try {
            List<FileItem> files = this.getUploadFiles(request);
            for (FileItem file : files) {
                if (fileFieldName.equals(file.getFieldName())) {
                    SpreadsheetConverter converter = this.converterMap.get(file.getContentType());
                    if (converter != null) {
                        try {
                            SpreadsheetConversion conversion = converter.convert(file.getInputStream());
                            for (String sheetName : conversion.getSheetNames()) {
                                for (String objectId : conversion.getObjectIds(sheetName)) {
                                    System.out.println("-------------------------------------");
                                    SpreadsheetConversion.ObjectData object = conversion.getObject(sheetName, objectId);

                                    ObjectType objectType = converter.getObjectType(object.getSheetName());
                                    String operation = object.getOperation();
                                    JSONObject data = object.convert();

                                    UUID uuid = null;
                                    try {
                                        UUID.fromString(object.getId());
                                    } catch (IllegalArgumentException e) {}

                                    Future<String> moxResponse = objectType.sendCommand(this.moxSender, operation, uuid, data, authorization);
                                    output.append(moxResponse.get());
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

    private String getSecurityToken() {
        Process p = null;
        try {
            p = Runtime.getRuntime().exec("/home/mox/mox/auth/auth.sh -s -u admin -p admin -i localhost:5672");
            BufferedReader stdOut = new BufferedReader(new InputStreamReader(p.getInputStream()));

            BufferedReader stdError = new BufferedReader(new
                    InputStreamReader(p.getErrorStream()));

            // read the output from the command
            String line;
            while ((line = stdOut.readLine()) != null) {
                System.out.println(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }
}
