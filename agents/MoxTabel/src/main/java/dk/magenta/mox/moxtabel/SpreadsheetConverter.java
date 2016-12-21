package dk.magenta.mox.moxtabel;

import org.apache.log4j.Logger;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Created by lars on 26-11-15.
 */
public abstract class SpreadsheetConverter {

    protected static SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    private static Logger log = Logger.getLogger(SpreadsheetConverter.class);

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

    public SpreadsheetConversion convert(File data) throws Exception {
        return null;
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
    private static void loadConverters() throws IOException {
        ArrayList<SpreadsheetConverter> converterList = new ArrayList<SpreadsheetConverter>();
        converterList.add(new OdfConverter());
        converterList.add(new XlsConverter());
        converterList.add(new XlsxConverter());
        converterMap = new HashMap<String, SpreadsheetConverter>();
        for (SpreadsheetConverter converter : converterList) {
            for (String contentType : converter.getApplicableContentTypes()) {
                converterMap.put(contentType, converter);
            }
        }
    }

    public static SpreadsheetConverter getConverter(String contentType) throws IOException {
        if (converterMap == null) {
            loadConverters();
        }
        if (!converterMap.containsKey(contentType)) {
            log.error("Could not find converter for content type '"+contentType+"'");
        }
        return converterMap.get(contentType);
    }

    public static SpreadsheetConversion getSpreadsheetConversion(InputStream data, String contentType) throws Exception {
        SpreadsheetConverter converter = getConverter(contentType);
        return converter.convert(data);
    }

    public static Map<String, Map<String, List<ConvertedObject>>> convert(InputStream data, String contentType) throws Exception {
        return getSpreadsheetConversion(data, contentType).getConvertedObjects();
    }

    public static SpreadsheetConversion getSpreadsheetConversion(File data, String contentType) throws Exception {
        SpreadsheetConverter converter = getConverter(contentType);
        return converter.convert(data);
    }

    public static Map<String, Map<String, List<ConvertedObject>>> convert(File data, String contentType) throws Exception {
        return getSpreadsheetConversion(data, contentType).getConvertedObjects();
    }

}
