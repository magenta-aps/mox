package dk.magenta.mox.auth;

import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.log4j.xml.DOMConfigurator;
import org.apache.rahas.TrustException;

import java.io.*;
import java.net.MalformedURLException;
import java.util.*;
import java.util.zip.GZIPOutputStream;

/**
 * Created by lars on 06-08-15.
 */
public class Main {
    public static Properties properties;

    boolean printHelp = false;
    boolean silent = false;
    String username = null;
    String password = null;
    String restInterface = null;
    String propertiesFileName = null;
    String stsAddress = null;

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        Main main = new Main();

        for (String arg : args) {
            if (arg.equalsIgnoreCase("help")) {
                main.printHelp();
                return;
            }
        }

        main.run(args);
    }

    private void printHelp() {
        System.out.println("Mox auth authentication interface");
        System.out.println("---------------------------");
        System.out.println("Will interface with a WSO2 server with a username and password, to obtain a valid authtoken");
        System.out.println("Usage: java -cp \"target/auth-1.0.jar:target/dependency/*\" dk.magenta.mox.auth.Main [-s] [-u username] [-p password] [-i interface] [-f propertiesfile] [-a stsAddress]\n");
        return;
    }

    private void print(String output) {
        if (!this.silent) {
            System.out.println(output);
        }
    }

    private void loadArgs(String[] argv) {
        HashMap<String, String> argMap = new HashMap<>();
        String currentKey = null;
        for (String a : argv) {
            String arg = a.trim();
            if (arg.startsWith("-")) {
                currentKey = arg.replace("-", "");
                argMap.put(currentKey, null);
            } else {
                argMap.put(currentKey, arg);
            }
        }

        if (argMap.containsKey("h")) {
            this.printHelp = true;
            return;
        }
        if (argMap.containsKey("s")) {
            this.silent = true;
        }
        if (argMap.containsKey("u")) {
            this.username = argMap.get("u");
            this.print("    username = " + this.username);
        }
        if (argMap.containsKey("p")) {
            this.password = argMap.get("p");
            if (this.password == null) {
                this.password = new String(System.console().readPassword("Password: "));
            } else {
                this.print("    password = ***");
            }
        }
        if (argMap.containsKey("i")) {
            this.restInterface = argMap.get("i");
            this.print("    restInterface = " + this.restInterface);
        }
        if (argMap.containsKey("f")) {
            this.propertiesFileName = argMap.get("f");
            this.print("    propertiesFilename = " + this.propertiesFileName);
        }
        if (argMap.containsKey("a")) {
            this.stsAddress = argMap.get("a");
            this.print("    stsAddress = " + this.stsAddress);
        }
    }

    private void loadPropertiesFile() {

        if (this.propertiesFileName == null) {
            this.propertiesFileName = "auth.properties";
            this.print("Loading default");
            this.print("    propertiesFilename = " + this.propertiesFileName);
        }

        File propertiesFile = new File(this.propertiesFileName);
        if (!propertiesFile.exists()) {
            System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " does not exist");
            return;
        } else if (!propertiesFile.canRead()) {
            System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " exist, but is unreadable by this user");
            return;
        }

        properties = new Properties();
        if (propertiesFile.canRead()) {
            try {
                properties.load(new FileInputStream(propertiesFile));
            } catch (IOException e) {
                System.err.println("Error loading from properties file " + propertiesFile.getAbsolutePath() + ": " + e.getMessage());
                return;
            }
            if (this.username == null || this.password == null || this.restInterface == null || this.stsAddress == null) {
                this.print("Reading properties file " + propertiesFile.getAbsolutePath());

                if (this.username == null) {
                    this.username = properties.getProperty("security.user.name");
                    this.print("    username = " + this.username);
                }
                if (this.password == null) {
                    this.password = properties.getProperty("security.user.password");
                    this.print("    password = ***");
                }
                if (this.restInterface == null) {
                    this.restInterface = properties.getProperty("rest.interface");
                    this.print("    restInterface = " + this.restInterface);
                }
                if (this.stsAddress == null) {
                    this.stsAddress = properties.getProperty("security.sts.address");
                    this.print("    stsAddress = " + this.stsAddress);
                }
            }
        }
    }

    private void run(String[] args) {

        this.loadArgs(args);
        if (this.printHelp) {
            this.printHelp();
            return;
        }
        this.loadPropertiesFile();

        properties.setProperty("security.user.name", this.username);
        properties.setProperty("security.user.password", this.password);
        properties.setProperty("security.sts.address", this.stsAddress);

        SecurityTokenObtainer securityTokenObtainer = null;
        try {
            securityTokenObtainer = new SecurityTokenObtainer(properties, this.silent);
        } catch (MissingPropertyException e) {
            e.printStackTrace();
        }

        try {
            String authtoken = securityTokenObtainer.getSecurityToken(this.restInterface);
            if (authtoken == null) {
                System.exit(1);
            }
            String encodedAuthtoken = "saml-gzipped " + base64encode(gzip(authtoken));
            System.out.println(encodedAuthtoken);

        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (SecurityTokenException e) {
            if (e.getCause() instanceof TrustException) {
                System.out.println("Incorrect password!");
                System.exit(1);
            } else if (e.getCause() instanceof ConnectTimeoutException) {
                System.out.println("Couldn't connect to Identity Provider "+properties.getProperty("security.sts.address"));
                System.exit(1);
            } else {
                e.printStackTrace();
            }
        }
        System.exit(0);
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
