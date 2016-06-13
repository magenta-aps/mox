package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.json.JSONObject;

import java.io.File;
import java.util.List;
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
                SpreadsheetConversion conversion;
                try {
                    conversion = SpreadsheetConverter.getSpreadsheetConversion(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                    Map<String, Map<String, List<ConvertedObject>>> objects = conversion.getConvertedObjects();

                    for (String sheetname : objects.keySet()) {
                        for (String id : objects.get(sheetname).keySet()) {
                            List<ConvertedObject> objectList = objects.get(sheetname).get(id);
                            for (ConvertedObject object : objectList) {
                                object.getJSON();
                                // System.out.println(sheetname+"/"+id+" : "+object.getJSON());
                            }
                        }
                    }


                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
