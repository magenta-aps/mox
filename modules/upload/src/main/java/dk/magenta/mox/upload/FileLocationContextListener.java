package dk.magenta.mox.upload;

/**
 * Created by lars on 22-01-16.
 */
import java.io.File;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class FileLocationContextListener implements ServletContextListener {

    public void contextInitialized(ServletContextEvent servletContextEvent) {
        ServletContext context = servletContextEvent.getServletContext();
        String rootPath = context.getRealPath("/");
        String relativePath = context.getInitParameter("tempfile.dir");
        File cacheFolder = new File(rootPath + File.separator + relativePath);
        if (!cacheFolder.exists()) {
            cacheFolder.mkdirs();
        }
        context.setAttribute(UploadServlet.cacheFolderNameConfigKey, cacheFolder.getPath());
    }

    public void contextDestroyed(ServletContextEvent servletContextEvent) {
        //do cleanup if needed
    }

}