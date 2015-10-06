package dk.magenta.mox.agent;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

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
        private String name;
        public Method method;
        public String path;
        public Operation(String name) {
            this.name = name;
        }
        public String toString() {
            return "Operation { \"name\":\""+this.name+"\", \"method\":\""+this.method.toString()+"\", \"path\":\""+this.path+"\" }";
        }
    }

    private static class Inheritance {
        public String inheritFrom;
        public String basePath;
    }

    private static final String COMMAND_CREATE = "create";
    private static final String COMMAND_READ = "read";
    private static final String COMMAND_SEARCH = "search";
    private static final String COMMAND_LIST = "list";
    private static final String COMMAND_UPDATE = "update";
    private static final String COMMAND_PASSIVATE = "passivate";
    private static final String COMMAND_DELETE = "delete";

    public ObjectType(String name) {
        this.name = name;
        this.operations = new HashMap<String, Operation>();
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("ObjectType { ");
        sb.append("\"name\":\""+this.name+"\",");
        sb.append("\"operations\":[");
        for (String operationName : this.operations.keySet()) {
            sb.append("\""+operationName+"\":");
            sb.append(this.operations.get(operationName).toString());
            sb.append(",");
        }
        sb.append("]");
        sb.append("}");
        return sb.toString();
    }

    private Operation addOperation(String name) {
        Operation operation = new Operation(name);
        this.operations.put(name, operation);
        return operation;
    }

    public Operation addOperation(String name, Method method, String path) {
        if (name != null) {
            Operation operation = this.addOperation(name);
            operation.method = method;
            operation.path = path;
            return operation;
        }
        return null;
    }

    public Operation getOperation(String name) {
        return this.getOperation(name, false);
    }

    public Operation getOperation(String name, boolean createIfMissing) {
        Operation operation = this.operations.get(name);
        if (operation == null && createIfMissing) {
            return this.addOperation(name);
        }
        return operation;
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
        HashMap<ObjectType, Inheritance> inheritances = new HashMap<>();
        for (String key : properties.stringPropertyNames()) {
            String[] path = key.split("\\.");
            if (path[0].equals("type")) {
                String name = path[1];
                ObjectType objectType = objectTypes.get(name);
                if (objectType == null) {
                    objectType = new ObjectType(name);
                    objectTypes.put(name, objectType);
                }
                String attributeValue = properties.getProperty(key);

                if (path.length >= 4 && !path[2].startsWith("_")) {
                    String operationName = path[2];
                    Operation operation = objectType.getOperation(operationName, true);
                    String attributeName = path[3].trim();
                    if (attributeName.equals("method")) {
                        try {
                            operation.method = Method.valueOf(attributeValue);
                        } catch (IllegalArgumentException e) {
                            String[] strings = new String[Method.values().length];
                            int i = 0;
                            for (Method m : Method.values()) {
                                strings[i++] = m.toString();
                            }
                            System.err.println("Error loading properties: method '" + attributeName + "' is not recognized. Recognized methods are: " + String.join(", ", strings));
                        }
                    } else if (attributeName.equals("path")) {
                        operation.path = attributeValue;
                    }
                } else if (path.length == 3 && path[2].startsWith("_")){
                    Inheritance inheritance = inheritances.get(objectType);
                    if (inheritance == null) {
                        inheritance = new Inheritance();
                        inheritances.put(objectType, inheritance);
                    }
                    if (path[2].equals("_basetype")) {
                        inheritance.inheritFrom = attributeValue;
                    } else if (path[2].equals("_basepath")) {
                        inheritance.basePath = attributeValue;
                    }
                }
            }
        }

        for (ObjectType objectType : inheritances.keySet()) {
            Inheritance inheritance = inheritances.get(objectType);
            ObjectType dependee = objectTypes.get(inheritance.inheritFrom);
            if (dependee == null) {
                System.err.println("Object type "+objectType.getName()+" inherits from Object type"+ inheritance.inheritFrom +", but it is not found");
            } else {
                String basepath = inheritance.basePath;
                for (String operationName : dependee.operations.keySet()) {
                    Operation dependeeOperation = dependee.getOperation(operationName);
                    Operation operation = objectType.getOperation(operationName, true);
                    operation.method = dependeeOperation.method;
                    operation.path = dependeeOperation.path.replace("[basepath]", basepath);
                }
            }
        }

        String[] neededOperations = {COMMAND_CREATE, COMMAND_READ, COMMAND_SEARCH, COMMAND_LIST, COMMAND_UPDATE, COMMAND_PASSIVATE, COMMAND_DELETE};
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





    public Future<String> create(MessageSender sender, JSONObject data) throws IOException, OperationNotSupportedException {
        return this.create(sender, data, null);
    }

    public Future<String> create(MessageSender sender, JSONObject data, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_CREATE);
        return this.sendCommand(sender, COMMAND_CREATE, null, data, authorization);
    }

    public Future<String> read(MessageSender sender, UUID uuid) throws IOException, OperationNotSupportedException {
        return this.read(sender, uuid, null);
    }

    public Future<String> read(MessageSender sender, UUID uuid, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_READ);
        return this.sendCommand(sender, COMMAND_READ, uuid, null, authorization);
    }

    public Future<String> search(MessageSender sender, ParameterMap<String, String> query) throws IOException, OperationNotSupportedException {
        return this.search(sender, query, null);
    }
    public Future<String> search(MessageSender sender, ParameterMap<String, String> query, String authorization) throws IOException, OperationNotSupportedException {
        return this.search(sender, query.toJSON(), authorization);
    }
    public Future<String> search(MessageSender sender, JSONObject query) throws IOException, OperationNotSupportedException {
        return this.search(sender, query, null);
    }
    public Future<String> search(MessageSender sender, JSONObject query, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_SEARCH);
        return this.sendCommand(sender, COMMAND_SEARCH, null, null, authorization, query);
    }

    public Future<String> list(MessageSender sender, UUID uuid, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_LIST);
        JSONObject query = new JSONObject();
        query.put("uuid", uuid.toString());
        return this.sendCommand(sender, COMMAND_LIST, null, null, authorization, query);
    }

    public Future<String> list(MessageSender sender, List<UUID> uuids, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_LIST);
        JSONObject query = new JSONObject();
        JSONArray list = new JSONArray();
        for (UUID uuid : uuids) {
            list.put(uuid.toString());
        }
        query.put("uuid", list);
        return this.sendCommand(sender, COMMAND_LIST, null, null, authorization, query);
    }


    public Future<String> update(MessageSender sender, UUID uuid, JSONObject data) throws IOException, OperationNotSupportedException {
        return this.update(sender, uuid, data, null);
    }

    public Future<String> update(MessageSender sender, UUID uuid, JSONObject data, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_UPDATE);
        return this.sendCommand(sender, COMMAND_UPDATE, uuid, data, authorization);
    }


    public Future<String> passivate(MessageSender sender, UUID uuid, String note) throws IOException, OperationNotSupportedException {
        return this.passivate(sender, uuid, note, null);
    }

    public Future<String> passivate(MessageSender sender, UUID uuid, String note, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_PASSIVATE);
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
        return this.sendCommand(sender, COMMAND_PASSIVATE, uuid, data, authorization);
    }

    public Future<String> delete(MessageSender sender, UUID uuid, String note) throws IOException, OperationNotSupportedException {
        return this.delete(sender, uuid, note, null);
    }

    public Future<String> delete(MessageSender sender, UUID uuid, String note, String authorization) throws IOException, OperationNotSupportedException {
        testOperationSupported(COMMAND_DELETE);
        JSONObject data = new JSONObject();
        if (note == null) {
            note = "";
        }
        try {
            data.put("Note", note);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return this.sendCommand(sender, COMMAND_DELETE, uuid, data, authorization);
    }





    public Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data) throws IOException {
        return this.sendCommand(sender, operationName, uuid, data, null, null);
    }
    public Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data, String authorization) throws IOException {
        return this.sendCommand(sender, operationName, uuid, data, authorization, null);
    }

    public Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data, String authorization, JSONObject query) throws IOException {
        HashMap<String, Object> headers = new HashMap<String, Object>();
        headers.put(MessageInterface.HEADER_OBJECTTYPE, this.name);
        headers.put(MessageInterface.HEADER_OPERATION, operationName);
        if (uuid != null) {
            headers.put(MessageInterface.HEADER_MESSAGEID, uuid.toString());
        }
        if (authorization != null) {
            headers.put(MessageInterface.HEADER_AUTHORIZATION, authorization);
        }
        if (query != null) {
            headers.put(MessageInterface.HEADER_QUERY, query.toString());
        }
        try {
            System.out.println("Sending:");
            System.out.println(headers);
            return sender.sendJSON(headers, data);
        } catch (InterruptedException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static String capitalize(String s) {
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }

    private void testOperationSupported(String operationName) throws OperationNotSupportedException {
        if (!this.operations.containsKey(operationName)) {
            throw new OperationNotSupportedException("Operation " + operationName + " is not defined for Object type " + this.name);
        }
    }

}
