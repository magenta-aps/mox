package dk.magenta.mox.agent;

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Properties;

/**
 * Created by lars on 15-02-16.
 */
public class MoxAgentBase {

    protected ParameterMap<String, String> commandLineArgs = null;
    protected Properties properties = null;
    protected ParameterMap<String, String> defaults = null;

    private File propertiesFile;

    protected static final String COMMAND_ARG_KEY = "__commands__";


    protected MoxAgentBase() {
    }

    public MoxAgentBase(String[] args) {
        this.loadArgs(args);
        try {
            this.loadProperties();
        } catch (IOException e) {
            e.printStackTrace();
        }
        this.loadDefaults();
    }

    protected void loadArgs(String[] commandlineArgs) {
        if (this.commandLineArgs == null) {
            System.out.println("Reading command line arguments");
            HashMap<String, ArrayList<String>> argMap = new HashMap<>();
            for (String arg : commandlineArgs) {
                try {
                    arg = arg.trim();
                    String key, value;
                    if (arg.startsWith("-")) {
                        arg = arg.substring(2);
                        String[] keyVal = arg.split("=", 2);
                        if (keyVal.length != 2) {
                            throw new IllegalArgumentException("Parameter " +
                                    arg + " must be of the format -Dparam=value");
                        }
                        key = keyVal[0];
                        value = keyVal[1];
                    } else if (!arg.isEmpty()) {
                        key = COMMAND_ARG_KEY;
                        value = arg;
                    } else {
                        continue;
                    }
                    if (!argMap.containsKey(key)) {
                        argMap.put(key, new ArrayList<>());
                    }
                    argMap.get(key).add(value);
                } catch (IllegalArgumentException e) {
                    e.printStackTrace();
                }
            }

            this.commandLineArgs = new ParameterMap<>();
            for (String key : argMap.keySet()) {
                this.commandLineArgs.put(key, argMap.get(key));
            }
        }
    }


    protected String getDefaultPropertiesFileName() {
        return "agent.properties";
    }

    protected void setPropertiesFile(String propertiesFileName) {
        if (propertiesFileName != null) {
            this.propertiesFile = new File(propertiesFileName);
        }
    }

    protected void loadProperties() throws IOException {
        if (this.properties == null) {
            this.properties = new Properties();

            if (this.commandLineArgs != null && this.propertiesFile == null) {
                this.setPropertiesFile(this.commandLineArgs.getFirst("propertiesFile"));
            }

            if (this.propertiesFile == null) {
                this.setPropertiesFile(this.getDefaultPropertiesFileName());
            }

            if (!this.propertiesFile.exists()) {
                throw new FileNotFoundException(this.propertiesFile.getAbsolutePath()+ "doesn't exist");
            }
            if (!this.propertiesFile.canRead()) {
                throw new IOException(this.propertiesFile.getAbsolutePath()+" is not readable");
            }

            if (this.propertiesFile.canRead()) {
                System.out.println("Loading config from '"+propertiesFile.getAbsolutePath()+"'");
                try {
                    properties.load(new FileInputStream(propertiesFile));
                } catch (IOException e) {
                    System.err.println("Error loading from properties file " + propertiesFile.getAbsolutePath() + ": " + e.getMessage());
                    return;
                }
            }
        }
    }

    protected void loadDefaults() {
        if (this.defaults == null) {
            System.out.println("Loading defaults");
            this.defaults = new ParameterMap<>();
        }
    }

    public String getSetting(String key) {
        String value = this.commandLineArgs.getFirst(key);
        if (value == null) {
            value = this.properties.getProperty(key);
        }
        if (value == null) {
            value = this.defaults.getFirst(key);
        }
        return value;
    }

    public List<String> getSettings(String key) {
        List<String> value = this.commandLineArgs.get(key);
        if (value == null) {
            String v = this.properties.getProperty(key);
            if (v != null) {
                value = new ArrayList<>();
                value.add(v);
            }
        }
        if (value == null) {
            value = this.defaults.get(key);
        }
        return value;
    }
}
