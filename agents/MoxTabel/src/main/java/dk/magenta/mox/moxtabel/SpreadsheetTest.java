package dk.magenta.mox.moxtabel;

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
                // String canonicalFilename = file.getName();
                // String extension = canonicalFilename.contains(".") ? canonicalFilename.substring(canonicalFilename.lastIndexOf(".")) : "";
                SpreadsheetConversion conversion;
                try {
                    conversion = SpreadsheetConverter.getSpreadsheetConversion(file, "application/vnd.oasis.opendocument.spreadsheet");
                    Map<String, Map<String, List<ConvertedObject>>> objects = conversion.getConvertedObjects();

                    for (Map<String, List<ConvertedObject>> sheetObjects : objects.values()) {
                        for (List<ConvertedObject> objectList : sheetObjects.values()) {
                            for (ConvertedObject object : objectList) {
                                System.out.println("SUM: " + object.getJSON().toString(2));
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
