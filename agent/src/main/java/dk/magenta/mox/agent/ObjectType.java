package dk.magenta.mox.agent;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import javax.naming.OperationNotSupportedException;
import java.io.*;
import java.util.*;
import java.util.concurrent.Future;

/**
 * Created by lars on 30-07-15.
 */

public class ObjectType {
    private String name;
    private HashMap<String, Operation> operations;

    public enum Method {
        GET,
        POST,
        PUT,
        DELETE,
        HEAD
    }

    public class Operation {
        public Method method;
        public String path;
        public String command;
    }

    private static final String OPERATION_CREATE = "create";
    private static final String OPERATION_UPDATE = "update";
    private static final String OPERATION_PASSIVATE = "passivate";
    private static final String OPERATION_DELETE = "delete";

    private ObjectType(String name) {
        this.name = name;
        this.operations = new HashMap<String, Operation>();
    }

    public Operation addOperation(String name) {
        Operation operation = new Operation();
        this.operations.put(name, operation);
        return operation;
    }

    public Operation getOperation(String name, boolean createIfMissing) {
        Operation operation = this.operations.get(name);
        if (operation == null && createIfMissing) {
            return this.addOperation(name);
        }
        return operation;
    }

    public Operation getOperationByCommand(String command) {
        if (command != null) {
            for (Operation operation : this.operations.values()) {
                if (command.equals(operation.command)) {
                    return operation;
                }
            }
        }
        return null;
    }

    public boolean hasCommand(String command) {
        return (this.getOperationByCommand(command) != null);
    }

    public static Map<String,ObjectType> load(String propertiesFileName) throws IOException {
        return load(new File(propertiesFileName));
    }

    public static Map<String,ObjectType> load(File propertiesFile) throws IOException {
        Properties properties = new Properties();
        properties.load(new FileInputStream(propertiesFile));
        return load(properties);
    }

    public static Map<String,ObjectType> load(Properties properties) {
        HashMap<String, ObjectType> objectTypes = new HashMap<String, ObjectType>();
        for (String key : properties.stringPropertyNames()) {
            String[] path = key.split("\\.");
            if (path.length >= 4 && path[0].equals("type")) {
                String name = path[1];
                ObjectType objectType = objectTypes.get(name);
                if (objectType == null) {
                    objectType = new ObjectType(name);
                    objectTypes.put(name, objectType);
                }
                String operationName = path[2];
                Operation operation = objectType.getOperation(operationName, true);
                String attributeName = path[3].trim();
                String attributeValue = properties.getProperty(key);
                if (attributeName.equals("method")) {
                    try {
                        operation.method = Method.valueOf(attributeValue);
                    } catch (IllegalArgumentException e) {
                        String[] strings = new String[Method.values().length];
                        int i=0;
                        for (Method m : Method.values()) {
                            strings[i++] = m.toString();
                        }
                        System.err.println("Error loading properties: method '"+attributeName+"' is not recognized. Recognized methods are: " + String.join(", ", strings));
                    }
                } else if (attributeName.equals("path")) {
                    operation.path = attributeValue;
                } else if (attributeName.equals("command")) {
                    operation.command = attributeValue;
                }
            }
        }
        String[] neededOperations = {OPERATION_CREATE, OPERATION_UPDATE, OPERATION_PASSIVATE, OPERATION_DELETE};
        for (ObjectType objectType : objectTypes.values()) {
            for (String operation : neededOperations) {
                if (!objectType.operations.containsKey(operation)) {
                    System.err.println("Warning: Object type "+objectType.name+" does not contain the "+operation+" operation. Calls to methods using that operation will fail.");
                }
            }
        }
        return objectTypes;
    }

    public String getName() {
        return name;
    }


    private JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }


    public Future<String> create(MessageSender sender, String jsonFilename) throws IOException, JSONException, OperationNotSupportedException {
        return this.create(sender, this.getJSONObjectFromFilename(jsonFilename));
    }

    public Future<String> create(MessageSender sender, JSONObject data) throws IOException, OperationNotSupportedException {
        if (this.operations.containsKey(OPERATION_CREATE)) {
            return this.sendCommand(sender, this.operations.get(OPERATION_CREATE).command, null, data);
        } else {
            throw new OperationNotSupportedException("Operation "+OPERATION_CREATE+" is not defined for Object type "+this.name);
        }
    }


    public void update(MessageSender sender, UUID uuid, String jsonFilename) throws IOException, JSONException, OperationNotSupportedException {
        this.update(sender, uuid, this.getJSONObjectFromFilename(jsonFilename));
    }

    public void update(MessageSender sender, UUID uuid, JSONObject data) throws IOException, OperationNotSupportedException {
        if (this.operations.containsKey(OPERATION_UPDATE)) {
            this.sendCommand(sender, this.operations.get(OPERATION_UPDATE).command, uuid, data);
        } else {
            throw new OperationNotSupportedException("Operation "+OPERATION_UPDATE+" is not defined for Object type "+this.name);
        }
    }


    public void passivate(MessageSender sender, UUID uuid, String note) throws IOException, OperationNotSupportedException {
        if (this.operations.containsKey(OPERATION_PASSIVATE)) {
            JSONObject data = new JSONObject();
            if (note == null) {
                note = "";
            }
            try {
                data.put("Note", note);
                data.put("livscyklus", "Passiv");
            } catch (JSONException e) {
                e.printStackTrace();
            }
            this.sendCommand(sender, this.operations.get(OPERATION_PASSIVATE).command, uuid, data);
        } else {
            throw new OperationNotSupportedException("Operation "+OPERATION_PASSIVATE+" is not defined for Object type "+this.name);
        }
    }

    public void delete(MessageSender sender, UUID uuid, String note) throws IOException, OperationNotSupportedException {
        if (this.operations.containsKey(OPERATION_DELETE)) {
            JSONObject data = new JSONObject();
            if (note == null) {
                note = "";
            }
            try {
                data.put("Note", note);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            this.sendCommand(sender, this.operations.get(OPERATION_DELETE).command, uuid, data);
        } else {
            throw new OperationNotSupportedException("Operation "+OPERATION_DELETE+" is not defined for Object type "+this.name);
        }
    }








    private Future<String> sendCommand(MessageSender sender, String operation, UUID uuid, JSONObject data) throws IOException {
        HashMap<String, Object> headers = new HashMap<String, Object>();
        headers.put("operation", operation);
        if (uuid != null) {
            headers.put("beskedID", uuid.toString());
        }
        try {
            return sender.sendJSON(headers, data);
        } catch (InterruptedException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static String capitalize(String s) {
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }

}
