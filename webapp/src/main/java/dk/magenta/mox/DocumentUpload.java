package dk.magenta.mox;

import dk.magenta.mox.agent.ObjectType;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.Writer;
import java.util.*;

/**
 * Created by lars on 26-11-15.
 */
@WebServlet(name = "DocumentUpload")
@MultipartConfig
public class DocumentUpload extends UploadServlet {

    private HashMap<String, SpreadsheetConverter> converterMap = new HashMap<String, SpreadsheetConverter>();

    public void init() throws ServletException {

        ArrayList<SpreadsheetConverter> converterList = new ArrayList<SpreadsheetConverter>();
        Properties agentProperties = new Properties();
        try {
            agentProperties.load(this.getServletContext().getResourceAsStream("/WEB-INF/agent.properties"));
        } catch (IOException e) {
            throw new ServletException("Failed to load /WEB-INF/agent.properties",e);
        }

        Map<String, ObjectType> objectTypes = ObjectType.load(agentProperties);

        try {
            converterList.add(new OdfConverter(objectTypes));
            converterList.add(new XlsConverter(objectTypes));
            converterList.add(new XlsxConverter(objectTypes));
        } catch (IOException e) {
            throw new ServletException("Failed converter initialization",e);
        }
        for (SpreadsheetConverter converter : converterList) {
            for (String contentType : converter.getApplicableContentTypes()) {
                this.converterMap.put(contentType, converter);
            }
        }
    }


    Logger log = Logger.getLogger(DocumentUpload.class);

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        final String fileFieldName = "file";


        Writer output = response.getWriter();

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
                                    JSONObject convertedObject = conversion.getConvertedObject(sheetName, objectId);
                                    System.out.println(convertedObject.toString(2));
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

    protected Map<String, String> parseContentDisposition(String contentDisposition) {
        HashMap<String, String> parsed = new HashMap<String, String>();
        for (String chunk : contentDisposition.split(";\\s*")) {
            int index = chunk.indexOf("=");
            if (index != -1) {
                parsed.put(chunk.substring(0, index), chunk.substring(index));
                System.out.println(chunk.substring(0, index)+"/"+chunk.substring(index+1));
            }
        }
        return parsed;
    }
}
