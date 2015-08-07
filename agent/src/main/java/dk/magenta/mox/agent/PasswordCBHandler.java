/*
*  Copyright (c) 2005-2010, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
*/
package dk.magenta.mox.agent;

import org.apache.ws.security.WSPasswordCallback;

import javax.security.auth.callback.Callback;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.callback.UnsupportedCallbackException;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class PasswordCBHandler implements CallbackHandler{
    
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
        Properties properties = new Properties();
        properties.load(new FileInputStream("agent.properties"));
        this.username = properties.getProperty("security.user.name");
        this.password = properties.getProperty("security.user.password");
        this.keyAlias = properties.getProperty("security.user.cert.alias");
        this.keyPassword = properties.getProperty("security.user.cert.password");
    }
}
