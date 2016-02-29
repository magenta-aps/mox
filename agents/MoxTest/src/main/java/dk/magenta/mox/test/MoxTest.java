package dk.magenta.mox.test;

import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.MoxAgent;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.util.concurrent.TimeoutException;

public class MoxTest extends MoxAgent {

    private Logger log = Logger.getLogger(MoxTest.class);
    private MessageSender sender;
    private String authToken;

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        MoxTest moxTest = new MoxTest(args);
    }

    public MoxTest(String[] args) {
        super(args);
        try {
            this.sender = this.createMessageSender();
            this.authToken = this.getAuthToken();
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }
    }

    private void testFacetOpret() {

    }


    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }

    private String getAuthToken() {
        try {
            Process authProcess = Runtime.getRuntime().exec(this.properties.getProperty("auth.command"));
            InputStream processOutput = authProcess.getInputStream();
            StringWriter writer = new StringWriter();
            IOUtils.copy(processOutput, writer);
            String output = writer.toString();
            String tokentype = this.properties.getProperty("auth.tokentype");
            if (tokentype != null) {
                int index = output.indexOf(tokentype);
                if (index != -1) {
                    int endIndex = output.indexOf("\n", index);
                    return output.substring(index, endIndex).trim();
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    protected String getDefaultPropertiesFileName() {
        return "moxtest.properties";
    }
}
