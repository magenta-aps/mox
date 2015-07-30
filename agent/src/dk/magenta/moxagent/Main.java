package dk.magenta.moxagent;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.UUID;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 29-07-15.
 */
public class Main {

    public static void main(String[] args) throws IOException, TimeoutException {
        MessageSender test = new MessageSender("localhost", null, "incoming");
        UUID uuid = UUID.randomUUID();
        sendCommand(test, "opretFacet", uuid, "test/facet_opret.json");
        sendCommand(test, "opdaterFacet", uuid, "test/facet_opdater.json");
        sendCommand(test, "opdaterFacet", uuid, "test/facet_passiv.json");
        sendCommand(test, "sletFacet", uuid, "test/facet_slet.json");

        uuid = UUID.randomUUID();
        sendCommand(test, "opretKlasse", uuid, "test/klasse_opret.json");
        sendCommand(test, "opdaterKlasse", uuid, "test/klasse_opdater.json");

        uuid = UUID.randomUUID();
        sendCommand(test, "opretItSystem", uuid, "test/itsystem_opret.json");

        test.close();
    }

    private static void sendCommand(MessageSender sender, String operation, UUID uuid, String jsonFilename) throws IOException {
        File testInput = new File(jsonFilename);
        try {
            JSONObject jsonObject = new JSONObject(new JSONTokener(new FileReader(testInput)));
            HashMap<String, Object> headers = new HashMap<String, Object>();
            headers.put("operation", operation);
            headers.put("beskedID", uuid.toString());
            sender.sendJSON(headers, jsonObject);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
