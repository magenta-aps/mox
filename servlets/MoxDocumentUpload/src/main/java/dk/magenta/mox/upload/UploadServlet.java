package dk.magenta.mox.upload;

/**
 * Created by lars on 22-01-16.
 */

import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.messages.UploadedDocumentMessage;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.*;
import java.net.InetAddress;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class UploadServlet extends HttpServlet {
    private ServletFileUpload uploader = null;

    public static final String UPLOAD_SERVLET_URL = "";
    public static final String cacheFolderNameConfigKey = "FILES_DIR";
    public static final String fileKey = "file";
    public static final String authKey = "authentication";

    private InetAddress localAddress;
    private static Pattern hostnamePattern = Pattern.compile("[a-z]+://([a-z0-9\\-\\.]+)(?::(\\d+))/.*", Pattern.CASE_INSENSITIVE);

    private MessageSender messageSender;

    private static boolean waitForAmqpResponses = true;

    private Logger log = Logger.getLogger(UploadServlet.class);

    @Override
    public void init() throws ServletException {
        try {
            this.log.info("\n--------------------------------------------------------------------------------");
            this.log.info("UploadServlet starting up");
            ServletContext context = getServletContext();
            File cacheFolder = new File((String) context.getAttribute(cacheFolderNameConfigKey));
            this.log.info("Cache folder: " + cacheFolder.getAbsolutePath());

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
        String fileName = request.getParameter("download");
        if (fileName != null && !fileName.equals("")) {
            this.log.info("File '"+fileName+"' requested");
            File file = new File(request.getServletContext().getAttribute(cacheFolderNameConfigKey) + File.separator + fileName);
            if (!file.exists()) {
                throw new ServletException("File doesn't exist on server.");
            }
            ServletContext ctx = getServletContext();
            InputStream fis = new FileInputStream(file);
            String mimeType = ctx.getMimeType(file.getAbsolutePath());
            response.setContentType(mimeType != null ? mimeType : "application/octet-stream");
            response.setContentLength((int) file.length());
            response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");

            ServletOutputStream os = response.getOutputStream();
            this.log.info("Sending file '"+fileName+"'");
            IOUtils.copy(fis, os);

            os.flush();
            os.close();
            fis.close();
            this.log.info("File '"+fileName+"' sent");
            return;
        }


        this.log.info("Sending Upload UI");
        Writer out = response.getWriter();
        out.append("<html>\n" +
                "<head></head>\n" +
                "<body>\n" +
                "<form action=\"\" method=\"post\" enctype=\"multipart/form-data\">\n" +
                "    Select File to Upload:<input type=\"file\" name=\""+ fileKey +"\">\n" +
                "    <br/>\n" +
                "    Token:<textarea name=\""+ authKey +"\"></textarea>" +
                "    <input type=\"submit\" value=\"Upload\">\n" +
                "</form>\n" +
                "</body>\n" +
                "</html>");

        this.log.info("Upload UI sent");
    }


    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        this.log.info("----------------------------------------");
        this.log.info("Receiving POST request");
        if (!ServletFileUpload.isMultipartContent(request)) {
            throw new ServletException("Content type is not multipart/form-data");
        }

        String protocol = request.getProtocol().replaceAll("/.*", "");

        String hostname;
        int port = -1;

        Matcher m = hostnamePattern.matcher(request.getRequestURL().toString());
        if (m.find()) {
            hostname = m.group(1);
            if (m.group(2) != null) {
                port = Integer.parseInt(m.group(2), 10);
            }
        } else {
            hostname = this.localAddress.getHostName();
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
                try {
                    FileItem fileItem = fileItemsIterator.next();
                    if (fileItem.getFieldName().equals(fileKey)) {
                        File file = new File(request.getServletContext().getAttribute(cacheFolderNameConfigKey) + File.separator + fileItem.getName());
                        fileItem.write(file);
                        this.log.info("Received file " + file.getAbsolutePath());

                        String relativePath = UPLOAD_SERVLET_URL + "?download=" + fileItem.getName();

                        out.write("File " + fileItem.getName() + " uploaded successfully.");
                        out.write("<br/>");
                        out.write("<a href=\"" + relativePath + "\">Download " + fileItem.getName() + "</a>");

                        String path = this.getServletContext().getContextPath() + "/" + relativePath;
                        UploadedDocumentMessage message = new UploadedDocumentMessage(fileItem.getName(), new URL(protocol, hostname, port, path), authorization);
                        messages.add(message);
                    }
                } catch (Exception e) {
                    out.write("Error when writing file to cache.");
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
                        String realResponse = amqpResponse.get(30, TimeUnit.SECONDS);
                        out.write(realResponse);
                    } catch (InterruptedException | ExecutionException | TimeoutException e) {
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

}