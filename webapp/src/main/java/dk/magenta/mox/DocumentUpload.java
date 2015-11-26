package dk.magenta.mox;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.io.Writer;
import java.util.Collection;
import java.util.HashMap;

/**
 * Created by lars on 26-11-15.
 */
@WebServlet(name = "DocumentUpload")
@MultipartConfig
public class DocumentUpload extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        final String fileFieldName = "file";

        Writer output = response.getWriter();

        Collection<Part> parts = request.getParts();
        if (parts.size() == 0) {
            throw new ServletException("The upload does not contain any files");
        }

        HashMap<String, Part> partMap = new HashMap<String, Part>();
        for (Part part : parts) {
            partMap.put(part.getName(), part);
        }

        if (partMap.containsKey(fileFieldName)) {
            InputStream dataStream = partMap.get(fileFieldName).getInputStream();
        } else {
            throw new ServletException("'"+fileFieldName+"' field not set in upload");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    }
}
