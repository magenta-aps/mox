/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.moxtabel;

import java.io.File;
import java.util.List;
import java.util.Map;

/**
 * Created by lars on 23-03-16.
 */
public class SpreadsheetTest {

    private static String odsType = "application/vnd.oasis.opendocument.spreadsheet";
    private static String csvType = "text/comma-separated-values";
    private static String xlsxType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    private static String xlsType = "application/vnd.ms-excel";

    public static void main(String[] args) {
        for (String filename : args) {
            File file = new File(filename);
            if (file.exists() && file.canRead()) {
                String canonicalFilename = file.getName();
                String extension = canonicalFilename.contains(".") ? canonicalFilename.substring(canonicalFilename.lastIndexOf(".")+1) : "";
                extension = extension.toLowerCase();
                String mimetype = odsType;
                if (extension.equals("ods")) {
                    mimetype = odsType;
                } else if (extension.equals("csv")) {
                    mimetype = csvType;
                } else if (extension.equals("xls")) {
                    mimetype = xlsType;
                } else if (extension.equals("xlsx")) {
                    mimetype = xlsxType;
                }

                try {
                    SpreadsheetConversion conversion = SpreadsheetConverter.getSpreadsheetConversion(file, mimetype);
                    Map<String, Map<String, List<ConvertedObject>>> objects = conversion.getConvertedObjects();

                    for (Map<String, List<ConvertedObject>> sheetObjects : objects.values()) {
                        for (List<ConvertedObject> objectList : sheetObjects.values()) {
                            for (ConvertedObject object : objectList) {
                                System.out.println(object.getId()+": "+object.getJSON().toString(2));
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
