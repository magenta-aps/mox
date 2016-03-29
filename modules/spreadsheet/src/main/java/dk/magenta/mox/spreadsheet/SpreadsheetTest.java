package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.json.JSONObject;

import java.io.File;
import java.util.Map;

/**
 * Created by lars on 23-03-16.
 */
public class SpreadsheetTest {

    public static void main(String[] args) {
        for (String filename : args) {
            File file = new File(filename);
            if (file.exists() && file.canRead()) {
                System.out.println("Parsing file " + file.getName());
                SpreadsheetConversion conversion = null;
                try {
                    conversion = SpreadsheetConverter.getSpreadsheetConversion(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                    Map<String, Map<String, ConvertedObject>> objects = conversion.getConvertedObjects();

                    JSONObject allStructures = new JSONObject();

                    for (String sheetname : objects.keySet()) {
                        Structure structure = new Structure();
                        structure.putAll(conversion.getSheet(sheetname).structure);
                        allStructures.put(sheetname, structure.toJSON());
                        for (String id : objects.get(sheetname).keySet()) {
                            ConvertedObject object = objects.get(sheetname).get(id);
                            object.getJSON();
                            //System.out.println(sheetname+"/"+id+" : "+object.getJSON());
                        }
                    }

                    System.out.println(allStructures.toString());

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
