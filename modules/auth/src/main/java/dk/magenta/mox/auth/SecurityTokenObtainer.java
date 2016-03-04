package dk.magenta.mox.auth;

import org.apache.axiom.om.OMAbstractFactory;
import org.apache.axiom.om.OMElement;
import org.apache.axiom.om.OMFactory;
import org.apache.axiom.om.impl.builder.StAXOMBuilder;
import org.apache.axis2.AxisFault;
import org.apache.axis2.context.ConfigurationContext;
import org.apache.axis2.context.ConfigurationContextFactory;
import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.neethi.Policy;
import org.apache.neethi.PolicyEngine;
import org.apache.rahas.*;
import org.apache.rahas.client.STSClient;
import org.apache.rampart.policy.model.CryptoConfig;
import org.apache.rampart.policy.model.RampartConfig;
import org.apache.ws.secpolicy.SP11Constants;
import org.apache.ws.security.WSPasswordCallback;

import javax.security.auth.callback.Callback;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.callback.UnsupportedCallbackException;
import javax.xml.namespace.QName;
import javax.xml.stream.XMLStreamException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.*;
import java.nio.file.attribute.PosixFilePermission;
import java.nio.file.attribute.PosixFilePermissions;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Properties;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;

/**
 * Created by lars on 25-11-15.
 */
public class SecurityTokenObtainer {

    private String keystorePath;
    private String keystorePass;
    private String repoPath;
    private String tokenType;
    private String subjectConfirmationMethod;
    private String claimDialect;
    private String[] claimUris;
    private String stsPolicyPath;
    private String username;
    private String encryptionUsername;
    private String userCertAlias;
    private String stsAddress;
    private String password;
    private String certPassword;

    private static final String SUBJECT_CONFIRMATION_BEARER = "b";
    private static final String SUBJECT_CONFIRMATION_HOLDER_OF_KEY = "h";
    private static final String SAML_TOKEN_TYPE_10 = "1.0";
    private static final String SAML_TOKEN_TYPE_11 = "1.1";
    private static final String SAML_TOKEN_TYPE_20 = "2.0";

    protected static Properties rampartProperties;

    public SecurityTokenObtainer(Properties properties) throws MissingPropertyException {
        this(properties, false);
    }

    public SecurityTokenObtainer(Properties properties, boolean silent) throws MissingPropertyException {
        String basedir = properties.getProperty("basedir","");
        if (!basedir.isEmpty() && !basedir.endsWith(File.separator)) {
            basedir = basedir + File.separator;
        }
        this.keystorePath = this.getPropertyOrThrow(properties, "security.keystore.path");
        this.keystorePass = this.getPropertyOrThrow(properties, "security.keystore.password");
        this.repoPath = basedir + this.getPropertyOrThrow(properties, "security.repo.path");
        this.tokenType = this.getPropertyOrThrow(properties, "security.saml.token.type");
        this.subjectConfirmationMethod = this.getPropertyOrThrow(properties, "security.subject.confirmation.method");
        this.claimDialect = this.getPropertyOrThrow(properties, "security.claim.dialect");
        this.claimUris = this.getPropertyOrThrow(properties, "security.claim.uris").split(",");
        this.stsPolicyPath = basedir + this.getPropertyOrThrow(properties, "security.sts.policy.path");
        this.username = this.getPropertyOrThrow(properties, "security.user.name");
        this.password = this.getPropertyOrThrow(properties, "security.user.password");
        this.encryptionUsername = this.getPropertyOrThrow(properties, "security.encryption.username");
        this.userCertAlias = this.getPropertyOrThrow(properties, "security.user.cert.alias");
        this.certPassword = this.getPropertyOrThrow(properties, "security.user.cert.password");
        this.stsAddress = this.getPropertyOrThrow(properties, "security.sts.address");
    }

    public String getSecurityToken(String endpointAddress) throws SecurityTokenException {
        String oldKeystorePath = System.getProperty("javax.net.ssl.trustStore");
        String oldKeystorePass = System.getProperty("javax.net.ssl.trustStorePassword");

        try {
            if (!(new File(this.keystorePath).exists())) {
                throw new FileNotFoundException("Keystore path '"+this.keystorePath+"' does not point to an existing file");
            }

            this.setSystemProperties(this.keystorePath, this.keystorePass);
            ConfigurationContext configCtx;

            String repoPath = this.repoPath;
            if (repoPath.contains(".jar!/")) {
                File unpacked = this.unpackFromJar(repoPath);
                repoPath = unpacked.getAbsolutePath();
            }
            configCtx = ConfigurationContextFactory.createConfigurationContextFromFileSystem(repoPath);

            // Create RST Template
            OMFactory omFac = OMAbstractFactory.getOMFactory();
            OMElement rstTemplate = omFac.createOMElement(SP11Constants.REQUEST_SECURITY_TOKEN_TEMPLATE);

            if (SAML_TOKEN_TYPE_20.equals(this.tokenType)) {
                TrustUtil.createTokenTypeElement(RahasConstants.VERSION_05_02, rstTemplate).setText(RahasConstants.TOK_TYPE_SAML_20);
            } else if (SAML_TOKEN_TYPE_11.equals(this.tokenType)) {
                TrustUtil.createTokenTypeElement(RahasConstants.VERSION_05_02, rstTemplate).setText(RahasConstants.TOK_TYPE_SAML_10);
            }

            if (SUBJECT_CONFIRMATION_BEARER.equals(this.subjectConfirmationMethod)) {
                TrustUtil.createKeyTypeElement(RahasConstants.VERSION_05_02, rstTemplate, RahasConstants.KEY_TYPE_BEARER);
            } else if (SUBJECT_CONFIRMATION_HOLDER_OF_KEY.equals(this.subjectConfirmationMethod)) {
                TrustUtil.createKeyTypeElement(RahasConstants.VERSION_05_02, rstTemplate, RahasConstants.KEY_TYPE_SYMM_KEY);
            }

            // request claims in the token.
            OMElement claimElement = TrustUtil.createClaims(RahasConstants.VERSION_05_02, rstTemplate, this.claimDialect);
            // Populate the <Claims/> element with the <ClaimType/> elements

            OMElement element;
            // For each and every claim uri, create an <ClaimType/> elem
            for (String attr : this.claimUris) {
                URI uri = new URI(attr);
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



            String stsPolicyPath = this.stsPolicyPath;
            if (stsPolicyPath.contains(".jar!/")) {
                File unpacked = unpackFromJar(stsPolicyPath);
                stsPolicyPath = unpacked.getAbsolutePath();
            }
            StAXOMBuilder omBuilder = new StAXOMBuilder(stsPolicyPath);
            Policy stsPolicy = PolicyEngine.getPolicy(omBuilder.getDocumentElement());


            // Build Rampart config

            SecurityTokenObtainer.rampartProperties = new Properties();
            SecurityTokenObtainer.rampartProperties.setProperty("security.user.name", this.username);
            SecurityTokenObtainer.rampartProperties.setProperty("security.user.password", this.password);
            SecurityTokenObtainer.rampartProperties.setProperty("security.user.cert.alias", this.userCertAlias);
            SecurityTokenObtainer.rampartProperties.setProperty("security.user.cert.password", this.certPassword);

            String pwdCallbackClass = PasswordCBHandler.class.getName();

            RampartConfig rampartConfig = new RampartConfig();
            rampartConfig.setUser(this.username);
            rampartConfig.setEncryptionUser(this.encryptionUsername);
            rampartConfig.setUserCertAlias(this.userCertAlias);
            rampartConfig.setPwCbClass(pwdCallbackClass);

            Properties cryptoProperties = new Properties();
            cryptoProperties.put("org.apache.ws.security.crypto.merlin.keystore.type", "JKS");
            cryptoProperties.put("org.apache.ws.security.crypto.merlin.file", this.keystorePath);
            cryptoProperties.put("org.apache.ws.security.crypto.merlin.keystore.password", this.keystorePass);

            CryptoConfig cryptoConfig = new CryptoConfig();
            cryptoConfig.setProvider("org.apache.ws.security.components.crypto.Merlin");
            cryptoConfig.setProp(cryptoProperties);

            rampartConfig.setEncrCryptoConfig(cryptoConfig);
            rampartConfig.setSigCryptoConfig(cryptoConfig);

            stsPolicy.addAssertion(rampartConfig);

            // request the security token from STS.
            Token responseToken = stsClient.requestSecurityToken(null, this.stsAddress, stsPolicy, endpointAddress);

            // store the obtained token in token store to be used in future communication.
            TokenStorage store = TrustUtil.getTokenStore(configCtx);
            responseTokenID = responseToken.getId();
            store.add(responseToken);

            return responseToken.getToken().toString();

        } catch (AxisFault e) {
            e.printStackTrace();
            this.setSystemProperties(oldKeystorePath, oldKeystorePass);
            throw new SecurityTokenException(e);

        } catch (TrustException e) {
            this.setSystemProperties(oldKeystorePath, oldKeystorePass);
            try {
                if (e.getCause().getCause() instanceof ConnectTimeoutException) {
                    throw new SecurityTokenException((ConnectTimeoutException) e.getCause().getCause());
                }
            } catch (NullPointerException ex) {
            }
            throw new SecurityTokenException(e);

        } catch (FileNotFoundException e) {
            e.printStackTrace();
            this.setSystemProperties(oldKeystorePath, oldKeystorePass);
            throw new SecurityTokenException(e);

        } catch (XMLStreamException e) {
            e.printStackTrace();
            this.setSystemProperties(oldKeystorePath, oldKeystorePass);
            throw new SecurityTokenException(e);
        } catch (URISyntaxException e) {
            e.printStackTrace();
            this.setSystemProperties(oldKeystorePath, oldKeystorePass);
            throw new SecurityTokenException(e);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private String getPropertyOrThrow(Properties properties, String key) throws MissingPropertyException {
        String value = properties.getProperty(key);
        if (value == null) {
            throw new MissingPropertyException(key);
        }
        return value;
    }

    private void setSystemProperties(String trustStore, String trustStorePassword) {
        if (trustStore != null) {
            System.setProperty("javax.net.ssl.trustStore", trustStore);
        }
        if (trustStorePassword != null) {
            System.setProperty("javax.net.ssl.trustStorePassword", trustStorePassword);
        }
    }

    public static class PasswordCBHandler implements CallbackHandler {

        private String username;
        private String password;
        private String keyAlias;
        private String keyPassword;

        public void handle(Callback[] callbacks) throws IOException, UnsupportedCallbackException {

            this.readUsernamePasswordFromProperties();

            WSPasswordCallback pwcb = (WSPasswordCallback) callbacks[0];
            String id = pwcb.getIdentifier();
            int usage = pwcb.getUsage();

            if (usage == WSPasswordCallback.USERNAME_TOKEN) {

               if (this.username.equals(id)) {
                   pwcb.setPassword(this.password);
               }
            } else if (usage == WSPasswordCallback.SIGNATURE || usage == WSPasswordCallback.DECRYPT) {

                if (this.keyAlias.equals(id)) {
                    pwcb.setPassword(this.keyPassword);
                }
            }
        }

        public void readUsernamePasswordFromProperties() throws IOException{
            // Use the static properties from the Main class
            Properties properties = SecurityTokenObtainer.rampartProperties;
            this.username = properties.getProperty("security.user.name");
            this.password = properties.getProperty("security.user.password");
            this.keyAlias = properties.getProperty("security.user.cert.alias");
            this.keyPassword = properties.getProperty("security.user.cert.password");
        }
    }




    private HashMap<String, File> unpackedFiles = new HashMap<String, File>();

    private File unpackFromJar(String jarPath) throws IOException {
        if (jarPath.contains(".jar!/")) {
            int separatorIndex = jarPath.indexOf("!/");
            return this.unpackFromJar(jarPath.substring(0, separatorIndex), jarPath.substring(separatorIndex + 2));
        }
        return null;
    }
    private File unpackFromJar(String jarFilePath, String innerFilePath) throws IOException {
        ZipFile zf;
        try{
            zf = new ZipFile(jarFilePath);
        } catch(ZipException e){
            throw new Error(e);
        } catch(IOException e){
            throw new Error(e);
        }

        ZipEntry ze = zf.getEntry(innerFilePath);
        System.out.println("ze: "+ze);
        System.out.println("ze.isDirectory: "+ze.isDirectory());

        HashSet<PosixFilePermission> filePermissions = new HashSet<>();
        filePermissions.add(PosixFilePermission.OWNER_READ);
        filePermissions.add(PosixFilePermission.OWNER_WRITE);
        filePermissions.add(PosixFilePermission.OWNER_EXECUTE);

        File tmpFolder = this.unpackedFiles.get(jarFilePath);
        if (tmpFolder == null) {
            tmpFolder = Files.createTempDirectory(null, PosixFilePermissions.asFileAttribute(filePermissions)).toFile();
            this.unpackedFiles.put(jarFilePath, tmpFolder);
        }

        File requestedFile = null;
        Enumeration e = zf.entries();
        while(e.hasMoreElements()){
            ZipEntry entry = (ZipEntry) e.nextElement();
            String fileName = entry.getName();
            if (fileName.startsWith(innerFilePath)) {
                File file = new File(tmpFolder, fileName);
                if (fileName.equals(innerFilePath)) {
                    requestedFile = file;
                }
                if (entry.isDirectory()) {
                    file.mkdirs();
                } else {
                    file.getParentFile().mkdirs();
                    Files.copy(zf.getInputStream(ze), FileSystems.getDefault().getPath(file.getAbsolutePath()));
                }
            }
        }
        return requestedFile;
    }
}
