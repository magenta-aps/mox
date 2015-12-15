package dk.magenta.mox;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
;
import javax.servlet.ServletContext;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by lars on 26-11-15.
 */
@MultipartConfig
public class UploadServlet extends HttpServlet {

    protected List<FileItem> getUploadFiles(HttpServletRequest request) throws FileUploadException {
        DiskFileItemFactory diskFileItemFactory = new DiskFileItemFactory();
        //diskFileItemFactory.setSizeThreshold(4096);
        //diskFileItemFactory.setRepository(new File(System.getProperty("java.io.tmpdir")));
        //return new ServletFileUpload(diskFileItemFactory).parseRequest(request);


        ServletContext servletContext = this.getServletConfig().getServletContext();
        File repository = (File) servletContext.getAttribute("javax.servlet.context.tempdir");
        diskFileItemFactory.setRepository(repository);


        return new ServletFileUpload(diskFileItemFactory).parseRequest(request);
    }

    protected Map<String, String> parseContentDisposition(String contentDisposition) {
        HashMap<String, String> parsed = new HashMap<String, String>();
        if (contentDisposition != null) {
            for (String part : contentDisposition.split(";\\s+")) {
                part = part.trim();
                String key = part;
                String value = null;
                if (part.contains("=")) {
                    int eqIndex = part.indexOf("=");
                    key = part.substring(0, eqIndex);
                    value = part.substring(eqIndex + 1);
                    value = value.replaceAll("^\"|\"$", "");
                }
                parsed.put(key, value);
            }
        }
        return parsed;
    }
}
