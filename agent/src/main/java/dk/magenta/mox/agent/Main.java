package dk.magenta.mox.agent;

import com.rabbitmq.client.ConnectionFactory;
import org.apache.axiom.om.OMAbstractFactory;
import org.apache.axiom.om.OMElement;
import org.apache.axiom.om.OMFactory;
import org.apache.axiom.om.impl.builder.StAXOMBuilder;
import org.apache.axis2.AxisFault;
import org.apache.log4j.PropertyConfigurator;
import org.apache.neethi.Policy;
import org.apache.neethi.PolicyEngine;
import org.apache.rahas.*;
import org.apache.rahas.client.STSClient;
import org.apache.rampart.policy.model.CryptoConfig;
import org.apache.rampart.policy.model.RampartConfig;
import org.apache.ws.secpolicy.SP11Constants;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import javax.naming.OperationNotSupportedException;
import javax.xml.namespace.QName;
import javax.xml.stream.XMLStreamException;
import java.io.*;
import java.net.MalformedURLException;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeoutException;
import java.util.zip.GZIPOutputStream;


import org.apache.axis2.context.ConfigurationContext;
import org.apache.axis2.context.ConfigurationContextFactory;

/**
 * Created by lars on 06-08-15.
 */
public class Main {
    public static Properties properties;

    public static void main(String[] args) {

        PropertyConfigurator.configure("log4j.xml");

        String queueUsername = null;
        String queuePassword = null;
        String queueInterface = null;
        String queueName = null;
        String restInterface = null;

        for (String arg : args) {
            if (arg.equalsIgnoreCase("help")) {
                System.out.println("Mox agent message interface");
                System.out.println("---------------------------");
                System.out.println("Will interface with a RabbitMQ message queue and pass messages through to a REST interface");
                System.out.println("Usage: java -cp \"target/moxagent-1.0.jar:target/dependency/*\" dk.magenta.mox.agent.Main [parameters] command\n");

                System.out.println("-----------");
                System.out.println("Parameters:\n");
                System.out.println("propertiesFile (-DpropertiesFile=<file>):\n    A Java properties file that contains configuration values.\n    Any parameters not found on the command line will be loaded from there.\n    Should also contain configuration for a SAML token service.\n    If this parameter is unset, the file 'agent.properties' will be loaded.\n");
                System.out.println("queueUsername (-DqueueUsername=<queueUsername>):\n    The RabbitMQ username.\n    If this is neither found in the command line or in the properties file, the value defaults to "+ ConnectionFactory.DEFAULT_USER+".\n");
                System.out.println("queuePassword (-DqueuePassword=<queuePassword>):\n    The RabbitMQ password.\n    If this is neither found in the command line or in the properties file, the value defaults to "+ ConnectionFactory.DEFAULT_PASS+".\n");
                System.out.println("queueInterface (-DqueueInterface=<hostname>:<port>):\n    An interface (<hostname>:<port>) where an instance of RabbitMQ is listening.\n    If this is neither found in the command line or in the properties file, the value defaults to localhost:5672.\n");
                System.out.println("queueName (-DqueueName=<name>):\n    The name of the RabbitMQ queue to send or receive messages in.\n    Defaults to 'incoming' if not found elsewhere.\n");
                System.out.println("restInterface (-DrestInterface=<protocol>://<hostname>:<port>):\n    The REST interface where messages should end up when passed through the queue.\n    Also needed for obtaining a SAML token for authenticating to that interface.\n    Defaults to http://127.0.0.1:5000\n");
                System.out.println("stsAddress " + "" + "(-DstsAddress=<protocol>://<hostname>:<port>):\n   The address of a Security Token Service, for requesting a SAML Security Token\n");

                System.out.println("---------");
                System.out.println("Commands:\n");
                System.out.println("listen\n    Starts a listener agent, which reads from the defined queue and sends requests to the defined REST interface\n");
                System.out.println("send [operation] [objecttype] [jsonfile]\n    Sends a messsage to the queue, telling listeners to perform [operation] on [objecttype] with data from [jsonfile].\n    E.g. 'send create facet facet.json'\n");
                System.out.println("sendtest\n    Runs a test by sending a series of messages to the queue, creating, updating, passivating and finally deleting a document.\n");
                System.out.println("gettoken <username>)\n    Requests a security token as the username specified. The password must be entered on standard input..\n");
                return;
            }
        }

        System.out.println("Reading command line arguments");

        HashMap<String, String> argMap = new HashMap<String, String>();
        ArrayList<String> commands = new ArrayList<String>();
        try {
            for (String arg : args) {
                arg = arg.trim();
                if (arg.startsWith("-")) {
                    if (commands.size() > 0) {
                        throw new IllegalArgumentException("You cannot append parameters after the command arguments");
                    }
                    arg = arg.substring(2);
                    String[] keyVal = arg.split("=", 2);
                    if (keyVal.length != 2) {
                        throw new IllegalArgumentException("Parameter " +
                                arg + " must be of the format -Dparam=value");
                    }
                    argMap.put(keyVal[0], keyVal[1]);
                } else if (!arg.isEmpty()) {
                    commands.add(arg);
                }
            }
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
            return;
        }

        if (argMap.containsKey("amqp.username")) {
            queueInterface = argMap.get("amqp.username");
            System.out.println("    amqp.username = " + queueUsername);
        }

        if (argMap.containsKey("amqp.password")) {
            queueInterface = argMap.get("amqp.password");
            System.out.println("    amqp.password = " + queuePassword);
        }

        if (argMap.containsKey("amqp.interface")) {
            queueInterface = argMap.get("amqp.interface");
            System.out.println("    amqp.interface = " + queueInterface);
        }

        if (argMap.containsKey("amqp.queue")) {
            queueName = argMap.get("amqp.queue");
            System.out.println("    amqp.queue = " + queueName);
        }

        if (argMap.containsKey("rest.interface")) {
            restInterface = argMap.get("rest.interface");
            System.out.println("    rest.interface = " + restInterface);
        }


        String propertiesFilename = argMap.get("propertiesFile");
        File propertiesFile;

        if (propertiesFilename == null) {
            propertiesFilename = "agent.properties";
            propertiesFile = new File(propertiesFilename);
            if (!propertiesFile.canRead()) {
                System.err.println("Cannot read from default properties file " + propertiesFile.getAbsolutePath());
                return;
            }
        } else {
            propertiesFile = new File(propertiesFilename);
            if (!propertiesFile.exists()) {
                System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " does not exist");
                return;
            } else if (!propertiesFile.canRead()) {
                System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " exist, but is unreadable by this user");
                return;
            }
        }
        properties = new Properties();
        if (propertiesFile.canRead()) {
            try {
                properties.load(new FileInputStream(propertiesFile));
            } catch (IOException e) {
                System.err.println("Error loading from properties file " + propertiesFile.getAbsolutePath() + ": " + e.getMessage());
                return;
            }
            System.out.println("Reading properties file " + propertiesFile.getAbsolutePath());

            if (queueUsername == null) {
                queueUsername = properties.getProperty("amqp.username");
                if (queueUsername != null) {
                    System.out.println("    amqp.username = " + queueUsername);
                }
            }
            if (queuePassword == null) {
                queuePassword = properties.getProperty("amqp.password");
                if (queuePassword != null) {
                    System.out.println("    amqp.password = ********");
                }
            }
            if (queueInterface == null) {
                queueInterface = properties.getProperty("amqp.interface");
                System.out.println("    amqp.interface = " + queueInterface);
            }
            if (queueName == null) {
                queueName = properties.getProperty("amqp.queue");
                System.out.println("    amqp.queue = " + queueName);
            }
            if (restInterface == null) {
                restInterface = properties.getProperty("rest.interface");
                System.out.println("    rest.interface = " + restInterface);
            }
            if (commands.isEmpty()) {
                String cmds = properties.getProperty("command", "");
                for (String command : cmds.split("\\s")) {
                    if (command != null && !command.trim().isEmpty()) {
                        commands.add(command.trim());
                    }
                }
                System.out.println("    commands = " + String.join(" ", commands));
            }
        }

        if (argMap.containsKey("stsAddress")) {
            properties.setProperty("security.sts.address", argMap.get("stsAddress"));
            System.out.println("    stsAddress = " + argMap.get("stsAddress"));
        }



        System.out.println("Loading defaults");

        if (queueInterface == null) {
            queueInterface = "localhost:5672";
            System.out.println("    amqp.interface = " + queueInterface);
        }
        if (queueName == null) {
            queueName = "incoming";
            System.out.println("    amqp.queue = " + queueName);
        }
        if (restInterface == null) {
            restInterface = "http://127.0.0.1:5000";
            System.out.println("    rest.interface = " + restInterface);
        }
        if (commands.isEmpty()) {
            commands.add("sendtest");
            System.out.println("    commands = sendtest");
        }


        try {
            Map<String, ObjectType> objectTypes = ObjectType.load(propertiesFile);

			if (commands.size() == 0) {
                throw new IllegalArgumentException("No commands defined");
            }
            String command = commands.get(0);


            if (command.equalsIgnoreCase("listen")) {

            	System.out.println("Listening for messages from RabbitMQ service at " + queueInterface + ", queue name '" + queueName + "'");
            	System.out.println("Successfully parsed messages will be forwarded to the REST interface at " + restInterface);
            	MessageReceiver messageReceiver = new MessageReceiver(queueUsername, queuePassword, queueInterface, null, queueName, true);
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
                MessageSender messageSender = new MessageSender(queueUsername, queuePassword, queueInterface, null, queueName);
                ObjectType objectType = objectTypes.get(objectTypeName);

                try {
                    if (operationName.equalsIgnoreCase("create")) {

                        try {
                            Future<String> response = objectType.create(messageSender, getJSONObjectFromFilename(commands.get(3)));
                            System.out.println(response.get());
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        } catch (ExecutionException e) {
                            e.printStackTrace();
                        } catch (OperationNotSupportedException e) {
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
                    throw new IllegalArgumentException("Incorrect number of arguments; the '" + command + "' command takes more arguments");
                }
                messageSender.close();



            } else if (command.equalsIgnoreCase("sendtest")) {

                System.out.println("Running sendtest\nSending to "+queueInterface+", queueName '"+queueName+"'");

                String encodedAuthtoken = null;
                if (properties.getProperty("security.enabled").equalsIgnoreCase("true")) {
                    String authtoken = getSecurityToken(properties, restInterface);
                    encodedAuthtoken = "saml-gzipped " + base64encode(gzip(authtoken));
                }

                MessageSender messageSender = new MessageSender(queueUsername, queuePassword, queueInterface, null, queueName);
                ObjectType objectType = objectTypes.get("facet");

                try {
                    Future<String> response;

                    System.out.println("Sending create operation");
                    response = objectType.create(messageSender, getJSONObjectFromFilename("test/facet_opret.json"), encodedAuthtoken);
                    String responseString = response.get();
                    System.out.println("create response: "+responseString);

                    JSONObject obj = new JSONObject(responseString);
                    UUID uuid = UUID.fromString(obj.getString("uuid"));

                    System.out.println("Sending read operation");
                    response = objectType.read(messageSender, uuid, encodedAuthtoken);
                    System.out.println("read response: "+response.get());

                    System.out.println("Sending search operation");
                    JSONObject jsonQuery = new JSONObject();
                    JSONArray array = new JSONArray();
                    array.put("ddc99abd-c1b0-48c2-aef7-74fea841adae");
                    array.put("ef2713ee-1a38-4c23-8fcb-3c4331262194");
                    jsonQuery.put("redaktoerer", array);
                    jsonQuery.put("status", "Publiceret");
                    jsonQuery.put("plan", "XYZ");
                    jsonQuery.put("brugervendtnoegle", "ORGFUNK");
                    jsonQuery.put("virkningFra", "2000-01-01");
                    jsonQuery.put("virkningTil", "2016-01-01");
                    response = objectType.search(messageSender, jsonQuery, encodedAuthtoken);
                    System.out.println("read response: " + response.get());

                    System.out.println("Sending search operation");
                    ParameterMap<String, String> query = new ParameterMap<>();
                    query.add("redaktoerer", "ddc99abd-c1b0-48c2-aef7-74fea841adae");
                    query.add("redaktoerer", "ef2713ee-1a38-4c23-8fcb-3c4331262194");
                    query.add("status", "Publiceret");
                    query.add("plan", "XYZ");
                    query.add("brugervendtnoegle", "ORGFUNK");
                    query.add("virkningFra", "2000-01-01");
                    query.add("virkningTil", "2016-01-01");
                    response = objectType.search(messageSender, query, encodedAuthtoken);
                    System.out.println("read response: " + response.get());

                    System.out.println("Sending list operation");
                    response = objectType.list(messageSender, uuid, encodedAuthtoken);
                    System.out.println("list response: "+response.get());

                    System.out.println("Sending list operation");
                    ArrayList<UUID> uuids = new ArrayList<>();
                    uuids.add(uuid);
                    response = objectType.list(messageSender, uuids, encodedAuthtoken);
                    System.out.println("list response: "+response.get());


                    System.out.println("Sending update operation");
                    response = objectType.update(messageSender, uuid, getJSONObjectFromFilename("test/facet_opdater.json"), encodedAuthtoken);
                    System.out.println("update response: "+response.get());

                    System.out.println("Sending passivate operation");
                    response = objectType.passivate(messageSender, uuid, null, encodedAuthtoken);
                    System.out.println("passivate response: "+response.get());

                    System.out.println("Sending delete operation");
                    response = objectType.delete(messageSender, uuid, "Delete that sucker", encodedAuthtoken);
                    System.out.println("delete response: "+response.get());


                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (ExecutionException e) {
                    e.printStackTrace();
                } catch (OperationNotSupportedException e) {
                    e.printStackTrace();
                }
            } else if (command.equalsIgnoreCase("gettoken")) {
                String restUsername = commands.get(1);
                if (restUsername == null) {
                    throw new IllegalArgumentException("Command argument <username>' must be specified");
                }
                String restPassword = String.valueOf(System.console().readPassword("Password:"));
                properties.setProperty("security.user.name", restUsername);
                properties.setProperty("security.user.password", restPassword);
                String authtoken = getSecurityToken(properties, restInterface);
                if (authtoken == null) {
                    System.exit(1);
                }
                String encodedAuthtoken = "saml-gzipped " + base64encode(gzip(authtoken));
                System.out.println(encodedAuthtoken);
            }
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.exit(0);
    }

    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }



    private static final String SUBJECT_CONFIRMATION_BEARER = "b";
    private static final String SUBJECT_CONFIRMATION_HOLDER_OF_KEY = "h";
    private static final String SAML_TOKEN_TYPE_10 = "1.0";
    private static final String SAML_TOKEN_TYPE_11 = "1.1";
    private static final String SAML_TOKEN_TYPE_20 = "2.0";

    public static String getSecurityToken(Properties properties, String endpointAddress) {

        try {
            String keystorePath = properties.getProperty("security.keystore.path");
            String keystorePass = properties.getProperty("security.keystore.password");
            String repoPath = properties.getProperty("security.repo.path");

            System.setProperty("javax.net.ssl.trustStore", keystorePath);
            System.setProperty("javax.net.ssl.trustStorePassword", keystorePass);

            ConfigurationContext configCtx = ConfigurationContextFactory.createConfigurationContextFromFileSystem(repoPath);


            // Create RST Template
            String tokenType = properties.getProperty("security.saml.token.type");
            OMFactory omFac = OMAbstractFactory.getOMFactory();
            OMElement rstTemplate = omFac.createOMElement(SP11Constants.REQUEST_SECURITY_TOKEN_TEMPLATE);

            if (SAML_TOKEN_TYPE_20.equals(tokenType)) {
                TrustUtil.createTokenTypeElement(RahasConstants.VERSION_05_02, rstTemplate).setText(RahasConstants.TOK_TYPE_SAML_20);
            } else if (SAML_TOKEN_TYPE_11.equals(tokenType)) {
                TrustUtil.createTokenTypeElement(RahasConstants.VERSION_05_02, rstTemplate).setText(RahasConstants.TOK_TYPE_SAML_10);
            }

            String subjectConfirmationMethod = properties.getProperty("security.subject.confirmation.method");
            if (SUBJECT_CONFIRMATION_BEARER.equals(subjectConfirmationMethod)) {
                TrustUtil.createKeyTypeElement(RahasConstants.VERSION_05_02, rstTemplate, RahasConstants.KEY_TYPE_BEARER);
            } else if (SUBJECT_CONFIRMATION_HOLDER_OF_KEY.equals(subjectConfirmationMethod)) {
                TrustUtil.createKeyTypeElement(RahasConstants.VERSION_05_02, rstTemplate, RahasConstants.KEY_TYPE_SYMM_KEY);
            }

            // request claims in the token.
            String claimDialect = properties.getProperty("security.claim.dialect");
            String[] claimUris = properties.getProperty("security.claim.uris", "").split(",");
            OMElement claimElement = TrustUtil.createClaims(RahasConstants.VERSION_05_02, rstTemplate, claimDialect);
            // Populate the <Claims/> element with the <ClaimType/> elements

            OMElement element;
            // For each and every claim uri, create an <ClaimType/> elem
            for (String attr : claimUris) {
                QName qName = new QName("http://schemas.xmlsoap.org/ws/2005/05/identity", "ClaimType", "wsid");
                element = claimElement.getOMFactory().createOMElement(qName, claimElement);
                element.addAttribute(claimElement.getOMFactory().createOMAttribute("Uri", null, attr));
            }


            // create STS client
            STSClient stsClient = new STSClient(configCtx);
            stsClient.setRstTemplate(rstTemplate);


            String action = null;
            String responseTokenID = null;

            action = TrustUtil.getActionValue(RahasConstants.VERSION_05_02, RahasConstants.RST_ACTION_ISSUE);
            stsClient.setAction(action);


            String stsPolicyPath = properties.getProperty("security.sts.policy.path");
            StAXOMBuilder omBuilder = new StAXOMBuilder(stsPolicyPath);
            Policy stsPolicy = PolicyEngine.getPolicy(omBuilder.getDocumentElement());


            // Build Rampart config
            String username = properties.getProperty("security.user.name");
            String encryptionUsername = properties.getProperty("security.encryption.username");
            String userCertAlias = properties.getProperty("security.user.cert.alias");
            String pwdCallbackClass = PasswordCBHandler.class.getCanonicalName();

            RampartConfig rampartConfig = new RampartConfig();
            rampartConfig.setUser(username);
            rampartConfig.setEncryptionUser(encryptionUsername);
            rampartConfig.setUserCertAlias(userCertAlias);
            rampartConfig.setPwCbClass(pwdCallbackClass);

            Properties cryptoProperties = new Properties();
            cryptoProperties.put("org.apache.ws.security.crypto.merlin.keystore.type", "JKS");
            cryptoProperties.put("org.apache.ws.security.crypto.merlin.file", keystorePath);
            cryptoProperties.put("org.apache.ws.security.crypto.merlin.keystore.password", keystorePass);

            CryptoConfig cryptoConfig = new CryptoConfig();
            cryptoConfig.setProvider("org.apache.ws.security.components.crypto.Merlin");
            cryptoConfig.setProp(cryptoProperties);

            rampartConfig.setEncrCryptoConfig(cryptoConfig);
            rampartConfig.setSigCryptoConfig(cryptoConfig);

            stsPolicy.addAssertion(rampartConfig);

            // request the security token from STS.

            String stsAddress = properties.getProperty("security.sts.address");
            Token responseToken = stsClient.requestSecurityToken(null, stsAddress, stsPolicy, endpointAddress);

            // store the obtained token in token store to be used in future communication.
            TokenStorage store = TrustUtil.getTokenStore(configCtx);
            responseTokenID = responseToken.getId();
            store.add(responseToken);

            return responseToken.getToken().toString();

        } catch (AxisFault axisFault) {
            axisFault.printStackTrace();
        } catch (TrustException e) {
            e.printStackTrace();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (XMLStreamException e) {
            e.printStackTrace();
        }
        return null;
    }

    private static byte[] gzip(String str) throws IOException{
        if (str == null || str.length() == 0) {
            return null;
        }

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        GZIPOutputStream gzip = new GZIPOutputStream(baos);
        gzip.write(str.getBytes());
        gzip.close();

        return baos.toByteArray();
    }

    private static String base64encode(byte[] data) {
        return Base64.getEncoder().encodeToString(data);
    }


}
