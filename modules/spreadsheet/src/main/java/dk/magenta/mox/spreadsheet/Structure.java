package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;
import org.apache.log4j.Logger;

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by lars on 23-03-16.
 */
public class Structure extends HashMap<String, ArrayList<String>> {

    private static Logger log = Logger.getLogger(Structure.class);

    public static Structure fromJSON(JSONObject object) {
        Structure structure = new Structure();
        for (String key : object.keySet()) {
            JSONArray list = object.getJSONArray(key);
            ArrayList<String> values = new ArrayList<>();
            for (int i=0; i<list.length(); i++) {
                values.add(i, list.getString(i));
            }
            structure.put(key, values);
        }
        return structure;
    }

    public JSONObject toJSON() {
        JSONObject obj = new JSONObject();
        for (String key : this.keySet()) {
            ArrayList<String> values = this.get(key);
            JSONArray list = new JSONArray();
            for (String item : values) {
                list.put(item);
            }
            obj.put(key, list);
        }
        return obj;
    }

    public static HashMap<String, Structure> allStructures = new HashMap<String, Structure>();

    static {
        File structuresFile = new File("structure.json");
        try {
            log.info("Loading structure from "+structuresFile.getCanonicalPath());
        } catch (IOException e) {
            log.info("Loading structure from structure.json");
        }
        if (!structuresFile.exists()) {
            log.error("File "+structuresFile+" does not exist");
        } else if (!structuresFile.canRead()) {
            log.error("File "+structuresFile+" is not readable");
        } else {
            // JSONObject structures = new JSONObject("{\"klasse\":{\"Kontekst\":[\"kontekst\",\"klasseegenskaber\",\"facet\"],\"LovligeKombinationer\":[\"relationer\",\"lovligekombinationer\",\"uuid\"],\"Erstatter\":[\"relationer\",\"erstatter\",\"uuid\"],\"Søgeord_beskrivelse\":[\"attributter\",\"klasseegenskaber\",\"soegeord\",\"beskrivelse\"],\"Aendringsnotat\":[\"attributter\",\"klasseegenskaber\",\"aendringsnotat\"],\"Eksempel\":[\"attributter\",\"klasseegenskaber\",\"eksempel\"],\"Redaktoerer_type\":[\"relationer\",\"redaktoerer\",\"objekttype\"],\"Operation\":[\"registrering\",\"operation\"],\"Omfang\":[\"attributter\",\"klasseegenskaber\",\"omfang\"],\"Mapninger\":[\"relationer\",\"mapninger\",\"uuid\"],\"Beskrivelse\":[\"attributter\",\"klasseegenskaber\",\"beskrivelse\"],\"Ejer\":[\"relationer\",\"ejer\",\"uuid\"],\"BrugervendtNoegle\":[\"attributter\",\"klasseegenskaber\",\"brugervendtnoegle\"],\"Retskilde\":[\"attributter\",\"klasseegenskaber\",\"retskildetekst\"],\"Ejer_type\":[\"relationer\",\"ejer\",\"objekttype\"],\"Facet\":[\"relationer\",\"facet\",\"uuid\"],\"Søgeord_kategori\":[\"attributter\",\"klasseegenskaber\",\"soegeord\",\"kategori\"],\"Tilfoejelser\":[\"relationer\",\"tilfoejelser\",\"uuid\"],\"Sideordnede\":[\"relationer\",\"sideordnede\",\"uuid\"],\"Søgeord\":[\"attributter\",\"klasseegenskaber\",\"soegeord\",\"soegeord\"],\"OverordnetKlasse\":[\"relationer\",\"overordnetklasse\",\"uuid\"],\"Redaktoerer\":[\"relationer\",\"redaktoerer\",\"uuid\"],\"Facet_type\":[\"relationer\",\"facet\",\"objekttype\"],\"Ansvarlig_type\":[\"relationer\",\"ansvarlig\",\"objekttype\"],\"Fra\":[\"virkning\"],\"Til\":[\"virkning\"],\"Titel\":[\"attributter\",\"klasseegenskaber\",\"titel\"],\"Note\":[\"registrering\",\"note\"],\"Publiceret\":[\"tilstande\",\"publiceret\"],\"objektID\":[\"registrering\",\"id\"],\"Ansvarlig\":[\"relationer\",\"ansvarlig\",\"uuid\"]},\"klassifikation\":{\"Kontekst\":[\"kontekst\",\"klassifikationegenskaber\",\"ejer\"],\"Kaldenavn\":[\"attributter\",\"klassifikationegenskaber\",\"kaldenavn\"],\"Operation\":[\"registrering\",\"operation\"],\"Ophavsret\":[\"attributter\",\"klassifikationegenskaber\",\"ophavsret\"],\"Beskrivelse\":[\"attributter\",\"klassifikationegenskaber\",\"beskrivelse\"],\"Ejer\":[\"relationer\",\"ejer\",\"uuid\"],\"Ansvarlig_type\":[\"relationer\",\"ansvarlig\",\"objekttype\"],\"Fra\":[\"virkning\"],\"BrugervendtNoegle\":[\"attributter\",\"klassifikationegenskaber\",\"brugervendtnoegle\"],\"Til\":[\"virkning\"],\"Note\":[\"registrering\",\"note\"],\"Publiceret\":[\"tilstande\",\"klassifikationpubliceret\",\"publiceret\"],\"objektID\":[\"registrering\",\"id\"],\"Ejer_type\":[\"relationer\",\"ejer\",\"objekttype\"],\"Ansvarlig\":[\"relationer\",\"ansvarlig\",\"uuid\"]},\"facet\":{\"Kontekst\":[\"kontekst\",\"facetegenskaber\",\"facettilhoerer\"],\"Redaktoerer_type\":[\"relationer\",\"redaktoerer\",\"objekttype\"],\"FacetTilhoerer_type\":[\"relationer\",\"facettilhoerer\",\"objekttype\"],\"Operation\":[\"registrering\",\"operation\"],\"PlanIdentifikator\":[\"attributter\",\"facetegenskaber\",\"planidentifikator\"],\"Ophavsret\":[\"attributter\",\"facetegenskaber\",\"ophavsret\"],\"Redaktoerer\":[\"relationer\",\"redaktoerer\",\"uuid\"],\"Beskrivelse\":[\"attributter\",\"facetegenskaber\",\"beskrivelse\"],\"Ejer\":[\"relationer\",\"ejer\",\"uuid\"],\"FacetTilhoerer\":[\"relationer\",\"facettilhoerer\",\"uuid\"],\"Ansvarlig_type\":[\"relationer\",\"ansvarlig\",\"objekttype\"],\"Fra\":[\"virkning\"],\"BrugervendtNoegle\":[\"attributter\",\"facetegenskaber\",\"brugervendtnoegle\"],\"Til\":[\"virkning\"],\"Note\":[\"registrering\",\"note\"],\"Supplement\":[\"attributter\",\"facetegenskaber\",\"supplement\"],\"Publiceret\":[\"tilstande\",\"facetpublicering\",\"publiceret\"],\"Retskilde\":[\"attributter\",\"facetegenskaber\",\"retskilde\"],\"objektID\":[\"registrering\",\"id\"],\"Ejer_type\":[\"relationer\",\"ejer\",\"objekttype\"],\"Opbygning\":[\"attributter\",\"facetegenskaber\",\"opbygning\"],\"Ansvarlig\":[\"relationer\",\"ansvarlig\",\"uuid\"]}}");
            JSONObject structures;
            try {
                structures = new JSONObject(structuresFile);
                for (String sheetname : structures.keySet()) {
                    allStructures.put(sheetname, Structure.fromJSON(structures.getJSONObject(sheetname)));
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            log.info("Loaded "+allStructures.size()+" structure objects");
        }

    }
}

