package dk.magenta.mox.agent;

import org.apache.axiom.om.OMAbstractFactory;
import org.apache.axiom.om.OMElement;
import org.apache.axiom.om.OMFactory;
import org.apache.axiom.om.impl.builder.StAXOMBuilder;
import org.apache.axis2.AxisFault;
import org.apache.axis2.context.ConfigurationContext;
import org.apache.axis2.context.ConfigurationContextFactory;
import org.apache.neethi.Policy;
import org.apache.neethi.PolicyEngine;
import org.apache.rahas.*;
import org.apache.rahas.client.STSClient;
import org.apache.rampart.policy.model.CryptoConfig;
import org.apache.rampart.policy.model.RampartConfig;
import org.apache.ws.secpolicy.SP11Constants;

import javax.xml.namespace.QName;
import javax.xml.stream.XMLStreamException;
import java.io.FileNotFoundException;
import java.util.Properties;

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

    private static final String SUBJECT_CONFIRMATION_BEARER = "b";
    private static final String SUBJECT_CONFIRMATION_HOLDER_OF_KEY = "h";
    private static final String SAML_TOKEN_TYPE_10 = "1.0";
    private static final String SAML_TOKEN_TYPE_11 = "1.1";
    private static final String SAML_TOKEN_TYPE_20 = "2.0";

    public SecurityTokenObtainer(Properties properties) {
        this.keystorePath = properties.getProperty("security.keystore.path");
        this.keystorePass = properties.getProperty("security.keystore.password");
        this.repoPath = properties.getProperty("security.repo.path");
        this.tokenType = properties.getProperty("security.saml.token.type");
        this.subjectConfirmationMethod = properties.getProperty("security.subject.confirmation.method");
        this.claimDialect = properties.getProperty("security.claim.dialect");
        this.claimUris = properties.getProperty("security.claim.uris", "").split(",");
        this.stsPolicyPath = properties.getProperty("security.sts.policy.path");
        this.username = properties.getProperty("security.user.name");
        this.encryptionUsername = properties.getProperty("security.encryption.username");
        this.userCertAlias = properties.getProperty("security.user.cert.alias");
        this.stsAddress = properties.getProperty("security.sts.address");
    }

    public String getSecurityToken(String endpointAddress) {
        String oldKeystorePath = System.getProperty("javax.net.ssl.trustStore");
        String oldKeystorePass = System.getProperty("javax.net.ssl.trustStorePassword");

        try {

            System.setProperty("javax.net.ssl.trustStore", this.keystorePath);
            System.setProperty("javax.net.ssl.trustStorePassword", this.keystorePass);

            ConfigurationContext configCtx = ConfigurationContextFactory.createConfigurationContextFromFileSystem(this.repoPath);

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


            StAXOMBuilder omBuilder = new StAXOMBuilder(this.stsPolicyPath);
            Policy stsPolicy = PolicyEngine.getPolicy(omBuilder.getDocumentElement());


            // Build Rampart config
            String pwdCallbackClass = PasswordCBHandler.class.getCanonicalName();

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

        } catch (AxisFault axisFault) {
            axisFault.printStackTrace();
        } catch (TrustException e) {
            e.printStackTrace();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (XMLStreamException e) {
            e.printStackTrace();
        }
        System.setProperty("javax.net.ssl.trustStore", oldKeystorePath);
        System.setProperty("javax.net.ssl.trustStorePassword", oldKeystorePass);

        return null;
    }
}
