package dk.magenta.mox;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import java.io.File;
import java.util.List;

/**
 * Created by lars on 26-11-15.
 */
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
}
