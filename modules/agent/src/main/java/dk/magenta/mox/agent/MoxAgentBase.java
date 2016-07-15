package dk.magenta.mox.agent;

import org.apache.log4j.Logger;

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
    protected Logger log = Logger.getLogger(MoxAgentBase.class);

    private ArrayList<File> propertiesFiles = new ArrayList<>();

    protected MoxAgentBase() {
    }

    public MoxAgentBase(String[] args) {
        this.loadArgs(args);
        try {
            this.loadProperties();
        } catch (IOException e) {
            this.log.error(e);
            e.printStackTrace();
        }
        this.loadDefaults();
    }

    protected void loadArgs(String[] commandlineArgs) {
        if (this.commandLineArgs == null) {
            this.log.info("Reading command line arguments");
            HashMap<String, ArrayList<String>> argMap = new HashMap<>();
            String currentKey = null;
            for (int i=0; i<commandlineArgs.length; i++) {
                String arg = commandlineArgs[i].trim();
                if (arg.startsWith("--")) {
                    currentKey = arg.substring(2);
                } else if (arg.startsWith("-")) {
                    currentKey = arg.substring(1);
                } else {
                    if (currentKey != null) {
                        if (!argMap.containsKey(currentKey)) {
                            argMap.put(currentKey, new ArrayList<>());
                        }
                        argMap.get(currentKey).add(arg);
                    }
                }
            }
            if (currentKey != null) {
                if (!argMap.containsKey(currentKey)) {
                    argMap.put(currentKey, new ArrayList<>());
                }
            }

            this.commandLineArgs = new ParameterMap<>();
            for (String key : argMap.keySet()) {
                this.commandLineArgs.put(key, argMap.get(key));
                this.log.info("    " + key + " = " + argMap.get(key));
            }
        }
    }


    protected String getDefaultPropertiesFileName() {
        return "agent.properties";
    }

    protected void addPropertiesFile(String propertiesFileName) throws IOException {
        if (propertiesFileName != null) {
            File propertiesFile = new File(propertiesFileName);
            if (!propertiesFile.exists()) {
                throw new FileNotFoundException(propertiesFile.getAbsolutePath()+ "doesn't exist");
            }
            if (!propertiesFile.canRead()) {
                throw new IOException(propertiesFile.getAbsolutePath()+" is not readable");
            }
            this.propertiesFiles.add(propertiesFile);
        }
    }

    protected void loadProperties() throws IOException {
        if (this.properties == null) {
            this.properties = new Properties();

            if (this.commandLineArgs != null) {
                List<String> propertiesFilenames = this.commandLineArgs.get("propertiesFile");
                if (propertiesFilenames != null) {
                    for (String filename : propertiesFilenames) {
                        this.addPropertiesFile(filename);
                    }
                }
            }

            if (this.propertiesFiles.isEmpty()) {
                this.addPropertiesFile(this.getDefaultPropertiesFileName());
            }

            for (File propertiesFile : this.propertiesFiles) {
                this.log.info("Loading config from '" + propertiesFile.getAbsolutePath() + "'");
                try {
                    properties.load(new FileInputStream(propertiesFile));
                    for (Object key : properties.keySet()) {
                        this.log.info("    " + key + " = " + properties.get(key));
                    }
                } catch (IOException e) {
                    this.log.warn("Error loading from properties file " + propertiesFile.getAbsolutePath() + ": " + e.getMessage());
                    return;
                }
            }
        }
    }

    protected void loadDefaults() {
        if (this.defaults == null) {
            this.log.info("Loading defaults");
            this.defaults = new ParameterMap<>();
        }
    }

    //--------------------------------------------------------------------------

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
