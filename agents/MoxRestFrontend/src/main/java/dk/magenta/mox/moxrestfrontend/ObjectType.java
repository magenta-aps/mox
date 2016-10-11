package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.messages.*;
import org.apache.log4j.Logger;

import javax.naming.OperationNotSupportedException;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;

/**
 * Created by lars on 30-07-15.
 */

public class ObjectType {
    private String name;
    private HashMap<String, Operation> operations;

    private Logger log = Logger.getLogger(ObjectType.class);

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
        try {
            return this.getOperation(name, createIfMissing, false);
        } catch (OperationNotSupportedException e) {
            e.printStackTrace(); // This can't really happen
            return null;
        }
    }

    public Operation getOperation(String name, boolean createIfMissing, boolean failIfMissing) throws OperationNotSupportedException {
        Operation operation = this.operations.get(name);
        if (operation == null) {
            if (createIfMissing) {
                return this.addOperation(name);
            } else if (failIfMissing) {
                this.testOperationSupported(name);
            }
        }
        return operation;
    }

    public boolean hasOperation(String operationName) {
        return this.operations.containsKey(operationName);
    }

    public static Map<String, ObjectType> load(String propertiesFileName) throws IOException {
        return load(new File(propertiesFileName));
    }

    public static Map<String, ObjectType> load(File propertiesFile) throws IOException {
        Properties properties = new Properties();
        properties.load(new FileInputStream(propertiesFile));
        return load(properties);
    }

    public static Map<String, ObjectType> load(Properties properties) {
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

        String[] neededOperations = {
                DocumentMessage.OPERATION_CREATE,
                DocumentMessage.OPERATION_READ,
                DocumentMessage.OPERATION_SEARCH,
                DocumentMessage.OPERATION_LIST,
                DocumentMessage.OPERATION_UPDATE,
                DocumentMessage.OPERATION_PASSIVATE,
                DocumentMessage.OPERATION_DELETE
        };
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


/*
    public CreateDocumentMessage create(String authorization, JSONObject data) {
        return new CreateDocumentMessage(authorization, data);
    }

    public ReadDocumentMessage read(String authorization, UUID uuid) {
        return new ReadDocumentMessage(authorization, uuid);
    }

    public SearchDocumentMessage search(ParameterMap<String, String> query, String authorization) {
        return new SearchDocumentMessage(authorization, query);
    }

    public ListDocumentMessage list(UUID uuid, String authorization) {
        return new ListDocumentMessage(authorization, uuid);
    }

    public ListDocumentMessage list(List<UUID> uuids, String authorization) {
        return new ListDocumentMessage(authorization, uuids);
    }

    public UpdateDocumentMessage update(UUID uuid, JSONObject data, String authorization) {
        return new UpdateDocumentMessage(authorization, uuid, data);
    }

    public PassivateDocumentMessage passivate(UUID uuid, String note, String authorization) {
        return new PassivateDocumentMessage(authorization, uuid, note);
    }

    public DeleteDocumentMessage delete(UUID uuid, String note, String authorization) throws IOException, OperationNotSupportedException {
        return new DeleteDocumentMessage(authorization, uuid, note);
    }
*/




/*
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
            return sender.sendJSON(headers, data);
        } catch (InterruptedException e) {
            e.printStackTrace();
            return null;
        }
    }*/

    private static String capitalize(String s) {
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }
    public void testOperationSupported(String operationName) throws OperationNotSupportedException {
        if (!this.hasOperation(operationName)) {
            throw new OperationNotSupportedException("Operation " + operationName + " is not defined for Object type " + this.name);
        }
    }

}
