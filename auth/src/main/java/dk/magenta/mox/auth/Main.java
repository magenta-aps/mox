package dk.magenta.mox.auth;

import gnu.getopt.Getopt;
import org.apache.log4j.xml.DOMConfigurator;
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
    String username = null;
    String password = null;
    String restInterface = null;
    String propertiesFileName = null;

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
        System.out.println("Usage: java -cp \"target/moxauth-1.0.jar:target/dependency/*\" dk.magenta.mox.auth.Main [-u username] [-p password] [-i interface] [-f propertiesfile]\n");
        return;
    }

    private void loadArgs(String[] argv) {
        Getopt getopt = new Getopt("testprog", argv, "hu:p:i:f:");

        System.out.println("Reading command line arguments");
        int c;
        while ((c = getopt.getopt()) != -1) {
            switch (c) {
                case 'h':
                    this.printHelp = true;
                    return;
                case 'u':
                    this.username = getopt.getOptarg();
                    System.out.println("    username = " + this.username);
                    break;
                case 'p':
                    this.password = getopt.getOptarg();
                    System.out.println("    password = ***");
                    break;
                case 'i':
                    this.restInterface = getopt.getOptarg();
                    System.out.println("    restInterface = " + this.restInterface);
                    break;
                case 'f':
                    this.propertiesFileName = getopt.getOptarg();
                    System.out.println("    propertiesFilename = " + this.propertiesFileName);
                    break;
            }
        }
    }

    private void loadPropertiesFile() {

        if (this.propertiesFileName == null) {
            this.propertiesFileName = "auth.properties";
            System.out.println("Loading default");
            System.out.println("    propertiesFilename = " + this.propertiesFileName);
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
            if (this.username == null || this.password == null || this.restInterface == null) {
                System.out.println("Reading properties file " + propertiesFile.getAbsolutePath());

                if (this.username == null) {
                    this.username = properties.getProperty("username");
                    System.out.println("    username = " + this.username);
                }
                if (this.password == null) {
                    this.password = properties.getProperty("password");
                    System.out.println("    password = ***");
                }
                if (this.restInterface == null) {
                    this.restInterface = properties.getProperty("restInterface");
                    System.out.println("    restInterface = " + this.restInterface);
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

        SecurityTokenObtainer securityTokenObtainer = null;
        try {
            securityTokenObtainer = new SecurityTokenObtainer(properties);
        } catch (MissingPropertyException e) {
            e.printStackTrace();
        }

        try {
            properties.setProperty("security.user.name", this.username);
            properties.setProperty("security.user.password", this.password);
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
            e.printStackTrace();
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
