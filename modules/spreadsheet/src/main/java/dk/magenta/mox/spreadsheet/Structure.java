package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;
import org.apache.log4j.Logger;

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Created by lars on 23-03-16.
 */
public class Structure {

    private static Logger log = Logger.getLogger(Structure.class);

    private HashMap<String, StructurePath> conversion;
    private ArrayList<StructurePath> lists;
    private ArrayList<StructurePath> mergelists;

    public Structure(JSONObject conversion, JSONArray lists, JSONArray mergelists) {
        this.conversion = new HashMap<>();
        for (String key : conversion.keySet()) {
            JSONArray valuePath = conversion.getJSONArray(key);
            this.conversion.put(key, new StructurePath(valuePath));
        }
        this.lists = new ArrayList<>();
        if (lists != null) {
            for (int i = 0; i < lists.length(); i++) {
                JSONArray list = lists.getJSONArray(i);
                this.lists.add(new StructurePath(list));
            }
        }
        this.mergelists = new ArrayList<>();
        if (mergelists != null) {
            for (int i = 0; i < mergelists.length(); i++) {
                JSONArray list = mergelists.getJSONArray(i);
                this.mergelists.add(new StructurePath(list));
            }
        }
    }

    public static Structure fromJSON(JSONObject object) {
        JSONObject conversion = object.getJSONObject("conversion");
        JSONArray lists = object.optJSONArray("lists");
        JSONArray mergelists = object.optJSONArray("mergelists");

        return new Structure(conversion, lists, mergelists);
    }

    public JSONObject toJSON() {
        JSONObject obj = new JSONObject();
        for (String key : this.conversion.keySet()) {
            StructurePath values = this.conversion.get(key);
            JSONArray list = new JSONArray();
            for (String item : values) {
                list.put(item);
            }
            obj.put(key, list);
        }
        return obj;
    }

    public StructurePath getConversionPath(String key) {
        return this.conversion.get(key);
    }
    public List<StructurePath> getLists() {
        return this.lists;
    }
    public boolean isList(StructurePath path) {
        for (StructurePath p : this.lists) {
            if (p.equals(path)) {
                return true;
            }
        }
        return false;
    }
    public boolean isMergeList(StructurePath path) {
        for (StructurePath p : this.mergelists) {
            if (p.equals(path)) {
                return true;
            }
        }
        return false;
    }

    public JSONObject addConversion(JSONObject base, String key, String value) {
        //System.out.println("------------------------");
        //System.out.println("base: "+base);
        //System.out.println("key: "+key);
        //System.out.println("value: "+value);
        StructurePath path = this.getConversionPath(key);
        //System.out.println("path: "+path);
        JSONObject ptr = base;
        for (int i=0; i<path.size(); i++) {

            StructurePath subPath = path.subPath(i);
            String pathKey = path.get(i);
            //System.out.println("pathKey: "+pathKey);

            if (i == path.size()-1) {
                ptr.put(pathKey, value);
            } else {
                if (this.isList(subPath)) {
                    //System.out.println(subPath+" is a list");
                    JSONArray arr = ptr.fetchJSONArray(pathKey);
                    //System.out.println("fetched "+arr+" from "+ptr);
                    if (arr.length() > 0) {
                        ptr = arr.getJSONObject(0);
                    } else {
                        ptr = new JSONObject();
                        arr.put(ptr);
                    }
                } else {
                    ptr = ptr.fetchJSONObject(pathKey);
                }
            }
            //System.out.println("ptr: "+ptr);
            //System.out.println("------");
        }
        return ptr;
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
            try {
                JSONObject structures = new JSONObject(structuresFile);
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

