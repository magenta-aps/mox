package dk.magenta.mox.agentdemo;

import com.sun.javaws.exceptions.InvalidArgumentException;
import dk.magenta.mox.agent.*;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import javax.naming.OperationNotSupportedException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 29-07-15.
 */
public class Main {

    public static void main(String[] args) throws IOException, TimeoutException {

        if (args.length == 0) {
            System.out.println("Demonstation program for mox agent communication");
            System.out.println("Example: listen localhost:5672 incoming http://127.0.0.1:5000");
        } else {
            HashMap<String, String> argMap = new HashMap<String, String>();
            ArrayList<String> commands = new ArrayList<String>();
            try {
                String paramKey = null;
                for (String arg : args) {
                    arg = arg.trim();
                    if (arg.startsWith("-")) {
                        if (commands.size() > 0) {
                            throw new InvalidArgumentException(new String[]{"You cannot append parameters after the command arguments"});
                        }
                        arg = arg.substring(1);
                        paramKey = arg;
                    } else if (!arg.isEmpty()) {
                        if (paramKey != null) {
                            argMap.put(paramKey, arg);
                            paramKey = null;
                        } else {
                            commands.add(arg);
                        }
                    }
                }
            } catch (InvalidArgumentException e) {
                e.printStackTrace();
                return;
            }

            String queueInterface = argMap.get("i");
            if (queueInterface == null) {
                queueInterface = "localhost:5672";
            }

            String queueName = argMap.get("n");
            if (queueName == null) {
                queueName = "incoming";
            }

            String restInterface = argMap.get("r");
            if (restInterface == null) {
                restInterface = "http://127.0.0.1:5000";
            }
            try {

                if (commands.size() == 0) {
                    throw new InvalidArgumentException(new String[]{"No commands defined"});
                }
                String command = commands.get(0);

                Map<String, ObjectType> objectTypes = ObjectType.load("agent.properties");

                if (command.equalsIgnoreCase("listen")) {
                    System.out.println("Listening on " + queueInterface + ", queue " + queueName);
                    System.out.println("Successfully parsed messages will be forwarded to the REST interface at " + restInterface);
                    MessageReceiver messageReceiver = new MessageReceiver(queueInterface, null, queueName, true);
                    try {
                        messageReceiver.run(new RestMessageHandler(restInterface, objectTypes));
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    messageReceiver.close();

                } else if (command.equalsIgnoreCase("send")) {
                    System.out.println("Sending to "+queueInterface+", queue "+queueName);

                    String operationName = commands.get(1);
                    String objectTypeName = commands.get(2);
                    MessageSender messageSender = new MessageSender(queueInterface, null, queueName);
                    ObjectType objectType = objectTypes.get(objectTypeName);

                    try {
                        if (operationName.equalsIgnoreCase("create")) {

                            Future<String> response = objectType.create(messageSender, getJSONObjectFromFilename(commands.get(3)));
                            try {
                                System.out.println(response.get());
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            } catch (ExecutionException e) {
                                e.printStackTrace();
                            }


                        } else if (operationName.equalsIgnoreCase("update")) {
                            objectType.update(messageSender, UUID.fromString(commands.get(3)), getJSONObjectFromFilename(commands.get(4)));
                        } else if (operationName.equalsIgnoreCase("passivate")) {
                            objectType.passivate(messageSender, UUID.fromString(commands.get(3)), commands.get(4));
                        } else if (operationName.equalsIgnoreCase("delete")) {
                            objectType.delete(messageSender, UUID.fromString(commands.get(3)), commands.get(4));
                        }

                    } catch (JSONException e) {
                        e.printStackTrace();
                    } catch (OperationNotSupportedException e) {
                        e.printStackTrace();
                    } catch (IndexOutOfBoundsException e) {
                        throw new InvalidArgumentException(new String[]{"Incorrect number of arguments; the '" + command + "' command takes more arguments"});
                    }
                    messageSender.close();

                } else if (command.equalsIgnoreCase("sendtest")) {
                    System.out.println("Running sendtest\nSending to "+queueInterface+", queue "+queueName);

                    String authorization = "incorrect";

                    MessageSender messageSender = new MessageSender(queueInterface, null, queueName);
                    ObjectType objectType = objectTypes.get("facet");

                    try {

                        try {
                            Future<String> response = objectType.create(messageSender, getJSONObjectFromFilename("test/facet_opret.json"), authorization);
                            String responseString = response.get();
                            System.out.println("create response: "+responseString);

                            JSONObject obj = new JSONObject(responseString);
                            UUID uuid = UUID.fromString(obj.getString("uuid"));

                            response = objectType.update(messageSender, uuid, getJSONObjectFromFilename("test/facet_opdater.json"), authorization);
                            responseString = response.get();
                            System.out.println("update response: "+responseString);

                            response = objectType.passivate(messageSender, uuid, "Pacify that sucker", authorization);
                            responseString = response.get();
                            System.out.println("passivate response: "+responseString);

                            response = objectType.delete(messageSender, uuid, "Delete that sucker", authorization);
                            responseString = response.get();
                            System.out.println("delete response: "+responseString);



                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        } catch (ExecutionException e) {
                            e.printStackTrace();
                        }




                    } catch (JSONException e) {
                        e.printStackTrace();
                    } catch (OperationNotSupportedException e) {
                        e.printStackTrace();
                    } catch (IndexOutOfBoundsException e) {
                        throw new InvalidArgumentException(new String[]{"Incorrect number of arguments; the '" + command + "' command takes more arguments"});
                    }
                    messageSender.close();


                } else if (command.equalsIgnoreCase("notify")) {
                    MessageSender sender = new MessageSender(queueInterface, null, queueName);
                    sender.sendFromGenerator(new DummyMessageGenerator());

                } else if (command.equalsIgnoreCase("getnotifications")) {
                    MessageReceiver receiver = new MessageReceiver(queueInterface, null, queueName, false);
                    try {
                        receiver.run(new PrintMessageHandler());
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }



            } catch (InvalidArgumentException e) {
                e.printStackTrace();
            }
        }
    }

    public static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }
}
