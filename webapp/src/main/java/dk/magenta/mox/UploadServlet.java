package dk.magenta.mox;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.util.*;

/**
 * Created by lars on 26-11-15.
 */
@MultipartConfig
public class UploadServlet extends HttpServlet {

    public class UploadedFile {
        private Part part;
        private Map<String, String> contentDisposition;

        public UploadedFile(Part part) {
            this.part = part;
            this.contentDisposition = UploadServlet.parseContentDisposition(part.getHeader("content-disposition"));
        }

        public String getFilename() {
            String filename = this.contentDisposition.get("filename");
            if (filename == null) {
                filename = this.part.getName();
            }
            return filename;
        }

        public String getPartName() {
            return this.part.getName();
        }

        public long getSize() {
            return this.part.getSize();
        }

        public InputStream getInputStream() throws IOException {
            return this.part.getInputStream();
        }

        public String getHeader(String key) {
            return this.part.getHeader(key);
        }

        public Collection<String> getHeaderNames() {
            return this.part.getHeaderNames();
        }

        public String getContentType() {
            return this.part.getContentType();
        }
    }

    protected List<UploadedFile> getUploadFiles(HttpServletRequest request) throws IOException, ServletException {
        ArrayList<UploadedFile> files = new ArrayList<UploadedFile>();
        for (Part part : request.getParts()) {
            if (part.getContentType() != null && part.getHeader("content-disposition") != null) {
                files.add(new UploadedFile(part));
            }
        }
        return files;
    }

    protected static Map<String, String> parseContentDisposition(String contentDisposition) {
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
