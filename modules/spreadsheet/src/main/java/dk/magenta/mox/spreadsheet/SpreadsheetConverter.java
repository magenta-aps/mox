package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.agent.ObjectType;

import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Created by lars on 26-11-15.
 */
public abstract class SpreadsheetConverter {

    protected Map<String, ObjectType> objectTypes;
    protected static SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    protected SpreadsheetConverter(Map<String, ObjectType> objectTypes) {
        this.objectTypes = objectTypes;
    }

    protected String[] getApplicableContentTypes() {
        return new String[0];
    }

    public boolean applies(String contentType) {
        for (String type : this.getApplicableContentTypes()) {
            if (type.equals(contentType)) {
                return true;
            }
        }
        return false;
    }

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        return null;
    }

    protected ObjectType getObjectType(String key) {
        ObjectType objectType = this.objectTypes.get(key);
        if (objectType == null) {
            for (String k : this.objectTypes.keySet()) {
                if (k.equalsIgnoreCase(key)) {
                    return this.objectTypes.get(k);
                }
            }
        }
        return objectType;
    }

    protected static boolean isRowdataEmpty(List<String> rowData) {
        if (rowData != null && !rowData.isEmpty()) {
            for (String s : rowData) {
                if (s != null && !s.isEmpty()) {
                    return false;
                }
            }
        }
        return true;
    }



    private static HashMap<String, SpreadsheetConverter> converterMap = null;
    private static void loadConverters(Properties properties) throws IOException {
        Map<String, ObjectType> objectTypes = ObjectType.load(properties);
        ArrayList<SpreadsheetConverter> converterList = new ArrayList<SpreadsheetConverter>();
        converterList.add(new OdfConverter(objectTypes));
        converterList.add(new XlsConverter(objectTypes));
        converterList.add(new XlsxConverter(objectTypes));
        converterMap = new HashMap<String, SpreadsheetConverter>();
        for (SpreadsheetConverter converter : converterList) {
            for (String contentType : converter.getApplicableContentTypes()) {
                converterMap.put(contentType, converter);
            }
        }
    }

    public static SpreadsheetConverter getConverter(String contentType) throws IOException {
        if (converterMap == null) {
            Properties properties = new Properties();
            properties.load(SpreadsheetConverter.class.getClassLoader().getResourceAsStream("objecttype.properties"));
            loadConverters(properties);
        }
        return converterMap.get(contentType);
    }

    public static SpreadsheetConversion convert(InputStream data, String contentType) throws Exception {
        SpreadsheetConverter converter = getConverter(contentType);
        return converter.convert(data);
    }

}
