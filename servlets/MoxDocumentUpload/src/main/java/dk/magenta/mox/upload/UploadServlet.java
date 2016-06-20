package dk.magenta.mox.upload;

/**
 * Created by lars on 22-01-16.
 */

import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.messages.UploadedDocumentMessage;
import dk.magenta.mox.json.JSONObject;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.text.StrSubstitutor;
import org.apache.http.entity.mime.HttpMultipartMode;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.log4j.Logger;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class UploadServlet extends HttpServlet {
    private ServletFileUpload uploader = null;
    private static final String createDocumentJsonTemplatePath =
            "/WEB-INF/json/create_document_template.json";

    public static final String UPLOAD_SERVLET_URL = "";
    public static final String cacheFolderNameConfigKey = "FILES_DIR";
    public static final String fileKey = "file";
    public static final String authKey = "authentication";

    private InetAddress localAddress;
    private static Pattern hostnamePattern = Pattern.compile("[a-z]+://([a-z0-9\\-\\.]+)(?::(\\d+))?/.*", Pattern.CASE_INSENSITIVE);

    private MessageSender messageSender;

    private static boolean waitForAmqpResponses = true;

    private Logger log = Logger.getLogger(UploadServlet.class);

    private URL restInterfaceURL = null;
    private String createDocumentJsonTemplateString;

    @Override
    public void init() throws ServletException {
        try {
            this.log.info("\n--------------------------------------------------------------------------------");
            this.log.info("UploadServlet starting up");
            ServletContext context = getServletContext();
            File cacheFolder = new File((String) context.getAttribute(cacheFolderNameConfigKey));
            this.log.info("Cache folder: " + cacheFolder.getAbsolutePath());

            try {
                restInterfaceURL = new URL(context.getInitParameter("rest.interface"));
            } catch (MalformedURLException e) {
                throw new ServletException("Rest interface URL is malformed", e);
            }

            InputStream jsonInputStream = getServletContext()
                    .getResourceAsStream(createDocumentJsonTemplatePath);
            if (jsonInputStream == null) {
                throw new ServletException("No JSON template found in WEB-INF"
                        + createDocumentJsonTemplatePath);
            }
            try {
                createDocumentJsonTemplateString = IOUtils.toString(jsonInputStream, StandardCharsets.UTF_8);
            } catch (IOException e) {
                e.printStackTrace();
            }

            if (!cacheFolder.isDirectory()) {
                throw new ServletException("Configured cacheFolder '" + cacheFolder.getAbsolutePath() + "' is not a directory");
            }
            if (!cacheFolder.canWrite()) {
                throw new ServletException("Configured cacheFolder '" + cacheFolder.getAbsolutePath() + "' is not writable");
            }

            DiskFileItemFactory fileFactory = new DiskFileItemFactory();
            this.log.info("DiskItemFileFactory created");
            fileFactory.setRepository(cacheFolder);

            this.uploader = new ServletFileUpload(fileFactory);
            this.uploader.setHeaderEncoding("UTF-8");
            this.log.info("Upload handler created");

            try {
                this.localAddress = InetAddress.getLocalHost();
            } catch (UnknownHostException e) {
                e.printStackTrace();
            }

            try {
                this.log.info("Creating MessageSender instance");
                this.messageSender = new MessageSender(
                        context.getInitParameter("amqp.username"),
                        context.getInitParameter("amqp.password"),
                        context.getInitParameter("amqp.interface"),
                        null,
                        context.getInitParameter("amqp.queue")
                );
                this.log.info("MessageSender created, will send to " + this.messageSender.getHost() + ", queueName " + this.messageSender.getQueueName());
            } catch (IOException e) {
                throw new ServletException("Unable to initialize MessageSender", e);
            } catch (TimeoutException e) {
                throw new ServletException("Unable to initialize MessageSender", e);
            }
        } catch (ServletException e) {
            e.printStackTrace();
            this.log.error("Servlet Exception", e);
            throw e;
        }
    }


    @Override
    public void destroy() {
        super.destroy();
        if (this.messageSender != null) {
            this.messageSender.close();
        }
    }


    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        this.log.info("----------------------------------------");
        this.log.info("Receiving GET request");

        this.log.info("Sending Upload UI");
        Writer out = response.getWriter();
        out.append("<html>\n" +
                "<head></head>\n" +
                "<body>\n" +
                "<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" accept-charset=\"UTF-8\">\n" +
                "    Select File to Upload: <input type=\"file\" name=\"" + fileKey + "\">\n" +
                "    <br/>\n" +
                "    Token: <textarea name=\"" + authKey + "\"></textarea>" +
                "    <input type=\"submit\" value=\"Upload\">\n" +
                "</form>\n" +
                "</body>\n" +
                "</html>");

        this.log.info("Upload UI sent");
    }


    /**
     * Returns the create document JSON string for a given document name.
     *
     * @param documentName The filename of the document.
     * @return String
     */
    protected String getCreateDocumentJson(String documentName, String mimetype) {
        Map<String, String> map = new HashMap<>();
        map.put("titel", documentName);
        map.put("beskrivelse", "MoxDokumentUpload");
        map.put("mimetype", mimetype);
        map.put("brugervendtnoegle", "brugervendtnoegle");
        map.put("virkning.from", ZonedDateTime.now().format(DateTimeFormatter.ISO_INSTANT));
        return StrSubstitutor.replace(createDocumentJsonTemplateString, map);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        this.log.info("----------------------------------------");
        this.log.info("Receiving POST request");
        if (!ServletFileUpload.isMultipartContent(request)) {
            throw new ServletException("Content type is not multipart/form-data");
        }

        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.write("<html><head></head><body>");

        try {

            List<FileItem> fileItemsList = uploader.parseRequest(request);
            Iterator<FileItem> fileItemsIterator = fileItemsList.iterator();

            String authorization = null;
            while (fileItemsIterator.hasNext()) {
                FileItem fileItem = fileItemsIterator.next();
                if (authKey.equals(fileItem.getFieldName())) {
                    authorization = new String(fileItem.get());
                }
            }
            fileItemsIterator = fileItemsList.iterator();

            ArrayList<UploadedDocumentMessage> messages = new ArrayList<>();
            while (fileItemsIterator.hasNext()) {
                FileItem fileItem = fileItemsIterator.next();
                if (fileItem.getFieldName().equals(fileKey)) {
                    String filename = fileItem.getName();
                    String mimetype = fileItem.getContentType();
                    JSONObject createDocumentJson = new JSONObject
                            (getCreateDocumentJson(filename, mimetype));

                    this.log.info("Received file " + filename);

                    HashMap<String, File> fileMap = new HashMap<>();
                    File tempFile = File.createTempFile("tmp", ".temp");
                    try {
                        fileItem.write(tempFile);
                    } catch (Exception e) {
                        throw new ServletException("Cannot create temporary " +
                                "file for uploaded file.", e);
                    }
                    fileMap.put("file", tempFile);
                    String result = sendMultipartRest("POST",
                            "/dokument/dokument", createDocumentJson.toString(), authorization, fileMap);
                    JSONObject jsonResult = new JSONObject(result);
                    String uuid = jsonResult.getString("uuid");

                    tempFile.delete();

                    out.write("Document " + filename + " uploaded " +
                            "successfully to OIO server.");
                    out.write("<br/>");
                    UploadedDocumentMessage message = new UploadedDocumentMessage(uuid, authorization);
                    messages.add(message);
                }
            }
            ArrayList<Future<String>> amqpResponses = new ArrayList<>();
            for (UploadedDocumentMessage message : messages) {
                try {
                    this.log.info("Sending message");
                    Future<String> amqpResponse = this.messageSender.send(message);
                    amqpResponses.add(amqpResponse);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            if (waitForAmqpResponses) {
                out.write("<br/>Response:<br/>");
                for (Future<String> amqpResponse : amqpResponses) {
                    try {
                        String realResponse = amqpResponse.get();
                        if (realResponse != null) {
                            out.write("<pre>");
                            out.write(realResponse);
                            out.write("</pre>");
                        }
                    } catch (InterruptedException | ExecutionException e) {
                        e.printStackTrace();
                    }
                }
            }
        } catch (FileUploadException e) {
            out.write("Exception in uploading file.");
            throw new ServletException(e);
        }
        out.write("</body></html>");
    }

    private URL getURLforPath(String path) throws MalformedURLException {
        return new URL(this.restInterfaceURL.getProtocol(), this.restInterfaceURL.getHost(), this.restInterfaceURL.getPort(), path);
    }

    /**
     * Make a multipart/form-data REST request with a JSON field.
     *
     * TODO: Move to RestClient.
     * @param method
     * @param path
     * @param json          The JSON to include in the field "json"
     * @param authorization
     * @param files         Mapping between multipart entity field name (key)
     *                      and File object (value)
     *                      to include in the request body.
     * @return
     * @throws IOException
     */
    private String sendMultipartRest(String method, String path, String json,
                                     String authorization, Map<String, File>
                                             files) throws IOException {
        URL url = getURLforPath(path);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(30000);
        connection.setDoOutput(true);
        if (authorization != null && !authorization.isEmpty()) {
            connection.setRequestProperty("Authorization", authorization.trim());
        }

        MultipartEntity multipartEntity = new MultipartEntity(HttpMultipartMode.STRICT);

        // Add the files to the request
        files.forEach((partName, file) -> {
            FileBody fileBody = new FileBody(file);
            multipartEntity.addPart(partName, fileBody);
        });

        multipartEntity.addPart("json", new StringBody(json,
                "application/json", StandardCharsets.UTF_8));

        connection.setRequestProperty("Content-Type", multipartEntity.getContentType().getValue());
        try (OutputStream out = connection.getOutputStream()) {
            multipartEntity.writeTo(out);
        }
        int status = connection.getResponseCode();
        this.log.info("Response status code: " + status);
        this.log.info("Sending message to REST interface: " + method + " " + url.toString() + " " + json);
        try {
            String response = IOUtils.toString(connection.getInputStream());
            this.log.info("got response");
            this.log.info(response);
            return response;
        } catch (ConnectException e) {
            this.log.warn("The defined REST interface (" + method + " " + connection.getURL().getHost() + ":" + connection.getURL().getPort() + connection.getURL().getPath() + ") does not answer.");
            throw e;
        } catch (IOException e) {
            this.log.warn("IOException on request to " + method + " " + url.toString() + ": " + e.getMessage());
            String response = IOUtils.toString(connection.getInputStream());
            if (response != null) {
                this.log.warn(response);
            }
            throw e;
        }
    }

}