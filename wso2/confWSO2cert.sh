#!/bin/bash
#
# Script to configure the WSO2 Identity Server with custom certificate
# Written on 13-jul-2016 by Ib-Michael Martinsen
#
if [ $(id -u) -ne 0 ]
then
	/bin/echo "This script must be executed as user 'root'"
	/bin/echo "Exitiing..."
	exit 250
fi

if [ -z "$NODEBUG" ]
then
	/bin/echo -e "DEBUG is on...\n"
fi

NOW=$(date +"%Y%m%d.%H%M%S")
MOXDIR="/srv/mox"

DOMAIN=$1
DOMAIN_DEF=$(hostname --fqdn)
CERTIFICATE_DEF=/etc/apache2/certs/magenta-aps.dk.crt
PRIVATE_KEY_DEF=/etc/apache2/certs/magenta-aps.dk.key
PASSOUT_DEF=wso2carbon

NEW_KEYSTORE_DEF=/opt/wso2is-5.0.0/repository/resources/security/newkeystore.jks
KEY_ALIAS_DEF=newalias
CLIENT_KEYSTORE_DEF=/opt/wso2is-5.0.0/repository/resources/security/client-truststore.jks

CARBON_XML=/opt/wso2is-5.0.0/repository/conf/carbon.xml
SECRET_CONF=/opt/wso2is-5.0.0/repository/conf/security/secret-conf.properties
MOX_AUTH_CONFIG="${MOXDIR}/modules/auth/auth.properties"
MOX_OIO_CONFIG="${MOXDIR}/oio_rest/oio_rest/settings.py"


function build_expect1_script() {
	if [ -f /tmp/expect1 ]
	then /bin/rm /tmp/expect1
	fi
	if [ -e /tmp/expect1 ]
	then /bin/echo "Cannot remove /tmp/expect1. Aborting..."
		exit 1
	fi
/bin/cat > /tmp/expect1 <<EOF
#!/usr/bin/expect -f

spawn openssl pkcs12 -export -in ${CERTIFICATE} -inkey ${PRIVATE_KEY} \
	-name ${KEY_ALIAS} -out ${CERTIFICATE_PKCS12}

set timeout 5

while {true} {
	expect	{
		"^Enter Export Password:$" {
			send_user "\n'Enter Export Password:' detected\n"
			sleep 1
			send "wso2carbon\r"
		}
		-re "Verifying"	{
			send_user "\n'Verifying' detected\n"
			sleep 1
			send "wso2carbon\r"
		}
		eof {
			send_user "Program termination detected. Exiting...\n"
			sleep 1
			exit
		}
	}
}
EOF
	/bin/chmod 500 /tmp/expect1
	/bin/echo "Expect script /tmp/expect1 is created"
}



function build_expect3_script() {
	if [ -f /tmp/expect3 ]
	then /bin/rm /tmp/expect3
	fi
	if [ -e /tmp/expect3 ]
	then /bin/echo "Cannot remove /tmp/expect3. Aborting..."
		exit 3
	fi
/bin/cat > /tmp/expect3 <<EOF
#!/usr/bin/expect -f

spawn /usr/bin/keytool -importkeystore -srckeystore ${CERTIFICATE_PKCS12} -srcstoretype PKCS12 \
		-destkeystore ${NEW_KEYSTORE} -deststoretype JKS \
		-srcstorepass ${PASSOUT} -deststorepass ${PASSOUT}

set timeout 5

while {true} {
	expect {
		"Existing entry alias ${KEY_ALIAS} exists, overwrite?" {
			send_user "\n'Existing entry alias ${KEY_ALIAS} exists, overwrite?' detected\n"
			sleep 1
			send "yes\r"
		}
		eof {
			send_user "Program termination detected. Exiting...\n"
			sleep 1
			exit
		}
	}
}
EOF
	/bin/chmod 500 /tmp/expect3
	/bin/echo "Expect script /tmp/expect3 is created"
}



function build_expect7_script() {
	if [ -f /tmp/expect7 ]
	then /bin/rm /tmp/expect7
	fi
	if [ -e /tmp/expect7 ]
	then /bin/echo "Cannot remove /tmp/expect7. Aborting..."
		exit 7
	fi
/bin/cat > /tmp/expect7 <<EOF
#!/usr/bin/expect -f

spawn /usr/bin/keytool -import -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} \
	-file ${PUBLIC_KEY} -storepass ${PASSOUT}

set timeout 5

while {true} {
	expect {
		"Trust this certificate?" {
			send_user "\n'Trust this certificate?' detected\n"
			sleep 1
			send "yes\r"
		}
		"Do you still want to add it?" {
			send_user "\n'Do you still want to add it?' detected\n"
			sleep 1
			send "yes\r"
		}
		"Certificate not imported, alias <${KEY_ALIAS}> already exists" {
			send_user "\n'Certificate not imported, alias '<${KEY_ALIAS}>' already exists' detected\n"
			sleep 1
			send "yes\r"
		}
		eof {
			send_user "Program termination detected. Exiting...\n"
			sleep 1
			exit
		}
	}
}
EOF
	/bin/chmod 500 /tmp/expect7
	/bin/echo "Expect script /tmp/expect7 is created"
}




/bin/echo "Timestamp: ${NOW}"

# Setup variables

if [[ -z "$DOMAIN" ]]; then
echo "domain is not set"
	QUIT="FALSE"
else
echo "domain is set"
	QUIT="TRUE"
fi


function prompt_var() {
	varname=$1
	default=$2
	promptmsg=$3
	errormsg=$4
	checkfile=$5
	
	QUIT=false
	while ! $QUIT
	do
		/bin/echo
		read -p "${promptmsg} [${default}]: " ANSWER
		VALUE=${ANSWER:-$default}

		if [ "${checkfile}" = true ]; then
			if [[ -f "${VALUE}" ]]
			then
				QUIT=true
			else
				/bin/echo "${errormsg}"
			fi
		else 
			if [[ -n "${VALUE}" ]]
			then
				QUIT=true
			else
				/bin/echo "${errormsg}"
			fi
		fi
	done
	eval "$varname='${VALUE}'"
}

if [[ -z "${DOMAIN}" ]]
then
	prompt_var DOMAIN "${DOMAIN_DEF}" "Domain name" "Empty domain" false
fi
prompt_var CERTIFICATE "${CERTIFICATE_DEF}" "Path for certificate" "Not a file" true
prompt_var PRIVATE_KEY "${PRIVATE_KEY_DEF}" "Path for certificate private key" "Not a file" true
prompt_var PASSOUT "${PASSOUT_DEF}" "Password for certificate/key_trust_stores" "Password must not be empty" false
prompt_var NEW_KEYSTORE "${NEW_KEYSTORE_DEF}" "Path for new keystore" "Name of new keystore must not be empty" true
prompt_var KEY_ALIAS "${KEY_ALIAS_DEF}" "Name for keyalias" "Alias must not be empty" false
prompt_var CLIENT_KEYSTORE "${CLIENT_KEYSTORE_DEF}" "Path for client truststore" "Not a file" true


CERTIFICATE_PKCS12=${CERTIFICATE%*.crt}.pfx
CERTIFICATE_PKCS12=${CERTIFICATE_PKCS12##*/}
PUBLIC_KEY=${CERTIFICATE%*.crt}.pubkey.pem
PUBLIC_KEY=${PUBLIC_KEY##*/}

if [ -z "$NODEBUG" ]
then
	/bin/echo "CERTIFICATE_PKCS12: ${CERTIFICATE_PKCS12}"
	/bin/echo "PUBLIC_KEY: ${PUBLIC_KEY}"
fi



if [ -z "$NODEBUG" ]
then
# Extract convert certificate to pkcs12 format with alias KEY_ALIAS
	/bin/echo
# Because the certificate is encoded with no/empty password and the option -passin does not except an empty password
# -passout will be the same as -password which in turn will submit the same password to the -passin parameter.
# This is obiviously wrong.
# To overcome it, we omit the password parameters and run the command with an expect script which takes care
# supplying the correct password.
#	/bin/echo openssl pkcs12 -export -in ${CERTIFICATE} -inkey ${PRIVATE_KEY} -name ${KEY_ALIAS} \
#		-out ${CERTIFICATE_PKCS12}
	/bin/echo openssl pkcs12 -export -in ${CERTIFICATE} -inkey ${PRIVATE_KEY} -name ${KEY_ALIAS} \
		-out ${CERTIFICATE_PKCS12}

# Backup old keystore if present
	if [[ -f "${NEW_KEYSTORE}" ]]
	then
		/bin/echo /bin/cp -p ${NEW_KEYSTORE} ${NEW_KEYSTORE}.${NOW}
	fi

# Create new keystore
	/bin/echo /usr/bin/keytool -importkeystore -srckeystore ${CERTIFICATE_PKCS12} -srcstoretype PKCS12 \
		-destkeystore ${NEW_KEYSTORE} -deststoretype JKS \
		-srcstorepass ${PASSOUT} -deststorepass ${PASSOUT}

# Backup old client-truststore
	if [[ -f "${CLIENT_KEYSTORE}" ]]
	then
		/bin/echo /bin/cp -p ${CLIENT_KEYSTORE} ${CLIENT_KEYSTORE}.${NOW}
	fi

# Export public key from new keystore certificate
	/bin/echo /usr/bin/keytool -export -alias ${KEY_ALIAS} -keystore ${NEW_KEYSTORE} \
	-storepass ${PASSOUT} -file ${PUBLIC_KEY}

# If public key is already present in client-truststore it has to be removed
	/bin/echo /usr/bin/keytool -list -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} -storepass ${PASSOUT} \| grep -qs "${KEY_ALIAS}"
	if [ $? -ne 0 ]
	then
		/bin/echo "Removing current key ${KEY_ALIAS}"
		/bin/echo /usr/bin/keytool -delete -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} -storepass ${PASSOUT}
	fi

# Import public key to client-truststore
	/bin/echo /usr/bin/keytool -import -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} \
	-file ${PUBLIC_KEY} -storepass ${PASSOUT}

# Backup old configuration files
	/bin/echo /bin/cp -p ${CARBON_XML} ${CARBON_XML}.${NOW}
	/bin/echo /bin/cp -p ${SECRET_CONF} ${SECRET_CONF}.${NOW}

echo "cert: ${CERTIFICATE}"

# Update auth.properties with new values
	/bin/echo sed -r -e "s|^security.keystore.path.*$|security.keystore.path = ${NEW_KEYSTORE}|" \
       -e "s|^security.keystore.password.*$|security.keystore.password = ${PASSOUT}|" \
       -e "s|^security.user.cert.alias.*$|security.user.cert.alias = ${KEY_ALIAS}|" \
       -e "s|^security.user.cert.password.*$|security.user.cert.password = ${PASSOUT}|" \
       ${MOX_AUTH_CONFIG} > ${MOX_AUTH_CONFIG}.$$

# Update oio settings.py with new values
	/bin/echo sed -r -e "s|^SAML_MOX_ENTITY_ID.*$|SAML_MOX_ENTITY_ID = 'https://${DOMAIN}'|" \
       -e "s|^SAML_IDP_URL.*$|SAML_IDP_URL = 'https://${DOMAIN}:9443/services/wso2carbon-sts?wsdl'|" \
       -e "s|^SAML_IDP_ENTITY_ID.*$|SAML_IDP_ENTITY_ID = '${DOMAIN}'|" \
       -e "s|^SAML_IDP_CERTIFICATE.*$|SAML_IDP_CERTIFICATE = '${CERTIFICATE}'|" \
       "${MOX_OIO_CONFIG}" > ${MOX_OIO_CONFIG}.$$

else
# Extract convert certificate to pkcs12 format with alias KEY_ALIAS
	/bin/echo step 1
# Because the certificate is encoded with no/empty password and the option -passin does not allow an empty password
# -passout will be the same as -password which in turn will submit the password as both the -passin and the -passout parameter.
# This is obviously wrong.
# To overcome it, we omit the password parameters and run the command with an expect script which takes care of
# supplying the correct password.
	build_expect1_script

#	/bin/echo openssl pkcs12 -export -in ${CERTIFICATE} -inkey ${PRIVATE_KEY} -name ${KEY_ALIAS} \
#		-out ${CERTIFICATE_PKCS12}
#	openssl pkcs12 -export -in ${CERTIFICATE} -inkey ${PRIVATE_KEY} -name ${KEY_ALIAS} \
#		-passout ${PASSOUT} -out ${CERTIFICATE_PKCS12}
#	openssl pkcs12 -export -in ${CERTIFICATE} -inkey ${PRIVATE_KEY} -name ${KEY_ALIAS} \
#		-out ${CERTIFICATE_PKCS12}

	/tmp/expect1

# Backup old keystore if present
	/bin/echo step 2
	if [[ -f "${NEW_KEYSTORE}" ]]
	then
		/bin/cp -p ${NEW_KEYSTORE} ${NEW_KEYSTORE}.${NOW}
	fi

# Create new keystore
	/bin/echo step 3
# If the new keystore already exist, we have to overwrite it using terminal input to accept overwriting.
# Hence, we use expect!
	build_expect3_script

#	/usr/bin/keytool -importkeystore -srckeystore ${CERTIFICATE_PKCS12} -srcstoretype PKCS12 \
#		-destkeystore ${NEW_KEYSTORE} -deststoretype JKS \
#		-srcstorepass ${PASSOUT} -deststorepass ${PASSOUT}

	/tmp/expect3

# Backup old client-truststore
	/bin/echo step 4
	if [[ -f "${CLIENT_KEYSTORE}" ]]
	then
		/bin/cp -p ${CLIENT_KEYSTORE} ${CLIENT_KEYSTORE}.${NOW}
	fi

# Export public key from new keystore certificate
	/bin/echo step 5
	/usr/bin/keytool -export -alias ${KEY_ALIAS} -keystore ${NEW_KEYSTORE} \
	-storepass ${PASSOUT} -file ${PUBLIC_KEY}

# If public key is already present in client-truststore it has to be removed
	/bin/echo step 6
	/usr/bin/keytool -list -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} -storepass ${PASSOUT} | grep -qs "${KEY_ALIAS}"
	if [ $? -eq 0 ]
	then
		/bin/echo "Removing current key ${KEY_ALIAS}"
		/usr/bin/keytool -delete -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} -storepass ${PASSOUT}
	fi

# Import public key to client-truststore
	/bin/echo step 7
# This keytool command expects terminal input, so we have to run it via expect
	build_expect7_script

#	/bin/echo /usr/bin/keytool -import -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} \
#	-file ${PUBLIC_KEY} -storepass ${PASSOUT}
#	/usr/bin/keytool -import -alias ${KEY_ALIAS} -keystore ${CLIENT_KEYSTORE} \
#	-file ${PUBLIC_KEY} -storepass ${PASSOUT}

	/tmp/expect7

# Backup old configuration files
	/bin/echo step 8
	/bin/cp -p ${CARBON_XML} ${CARBON_XML}.${NOW}
	/bin/cp -p ${SECRET_CONF} ${SECRET_CONF}.${NOW}
fi



# Customize configuration files
awk -v NKS=${NEW_KEYSTORE} -v PWD=${PASSOUT} -v ALIAS=${KEY_ALIAS} -v CKS=${CLIENT_KEYSTORE} -v DMN=${DOMAIN} '
BEGIN				{
				printline=1;
				}
/<HostName>.*<\/HostName>/ {
				printf("\t<HostName>%s</HostName>\n", DMN);
				printline=0;
                }
/<KeyStore>/,/<\/KeyStore>/	{
				if (index($0, "<Location>"))
					printf("\t\t<Location>%s</Location>\n", NKS);
				else if (index($0, "<Password>"))
					printf("\t\t<Password>%s</Password>\n", PWD);
				else if (index($0, "<KeyAlias>"))
					printf("\t\t<KeyAlias>%s</KeyAlias>\n", ALIAS);
				else if (index($0, "<KeyPassword>"))
					printf("\t\t<KeyPassword>%s</KeyPassword>\n", PWD);
				else
					print $0;
				printline=0;
				}
/<RegistryKeyStore>/,/<\/RegistryKeyStore>/	{
				if (index($0, "<Location>"))
					printf("\t\t<Location>%s</Location>\n", NKS);
				else if (index($0, "<Password>"))
					printf("\t\t<Password>%s</Password>\n", PWD);
				else if (index($0, "<KeyAlias>"))
					printf("\t\t<KeyAlias>%s</KeyAlias>\n", ALIAS);
				else if (index($0, "<KeyPassword>"))
					printf("\t\t<KeyPassword>%s</KeyPassword>\n", PWD);
				else
					print $0;
				printline=0;
				}
/<TrustStore>/,/<\/TrustStore>/	{
				if (index($0, "<Location>"))
					printf("\t\t<Location>%s</Location>\n", CKS);
				else if (index($0, "<Password>"))
					printf("\t\t<Password>%s</Password>\n", PWD);
				else
					print $0
				printline=0;
				}
				{
#				print "printline: ", printline;
				if (printline == 1)
					print $0;
				printline=1;
				}
' ${CARBON_XML} > ${CARBON_XML}.$$
if [ -z "$NODEBUG" ]
then
	/bin/echo
	/bin/cat ${CARBON_XML}.$$
else
	/bin/cp -p ${CARBON_XML}.$$ ${CARBON_XML}
fi
/bin/rm ${CARBON_XML}.$$



sed -r -e '/^keystore.identity/d' -e '/^keystore.trust/d' ${SECRET_CONF} > ${SECRET_CONF}.$$

/bin/cat >> ${SECRET_CONF}.$$ <<-EOF
keystore.identity.location=${NEW_KEYSTORE}
keystore.identity.type=JKS
keystore.identity.alias=${KEY_ALIAS}
keystore.identity.store.password=${PASSOUT}
keystore.identity.key.password=${PASSOUT}
#
keystore.trust.location=${CLIENT_KEYSTORE}
keystore.trust.type=JKS
keystore.trust.alias=${KEY_ALIAS}
keystore.trust.store.password=${PASSOUT}
EOF

if [ -z "$NODEBUG" ]
then
	/bin/echo
	/bin/cat ${SECRET_CONF}.$$
else
	/bin/cp -p ${SECRET_CONF}.$$ ${SECRET_CONF}
fi
/bin/rm ${SECRET_CONF}.$$


# Update auth.properties with new values
sed -r -e "s|^security.keystore.path.*$|security.keystore.path = ${NEW_KEYSTORE}|" \
       -e "s|^security.keystore.password.*$|security.keystore.password = ${PASSOUT}|" \
       -e "s|^security.user.cert.alias.*$|security.user.cert.alias = ${KEY_ALIAS}|" \
       -e "s|^security.user.cert.password.*$|security.user.cert.password = ${PASSOUT}|" \
       ${MOX_AUTH_CONFIG} > ${MOX_AUTH_CONFIG}.$$

# Update oio settings.py with new values
sed -r -e "s|^SAML_MOX_ENTITY_ID.*$|SAML_MOX_ENTITY_ID = 'https://${DOMAIN}'|" \
       -e "s|^SAML_IDP_URL.*$|SAML_IDP_URL = 'https://${DOMAIN}:9443/services/wso2carbon-sts?wsdl'|" \
       -e "s|^SAML_IDP_ENTITY_ID.*$|SAML_IDP_ENTITY_ID = '${DOMAIN}'|" \
       -e "s|^SAML_IDP_CERTIFICATE.*$|SAML_IDP_CERTIFICATE = '${CERTIFICATE}'|" \
       "${MOX_OIO_CONFIG}" > ${MOX_OIO_CONFIG}.$$

if [ -z "$NODEBUG" ]
then
	/bin/echo
	/bin/cat ${MOX_AUTH_CONFIG}.$$
	/bin/echo
	/bin/cat ${MOX_OIO_CONFIG}.$$
else
	/bin/cp -p ${MOX_AUTH_CONFIG}.$$ ${MOX_AUTH_CONFIG}
	/bin/cp -p ${MOX_OIO_CONFIG}.$$ ${MOX_OIO_CONFIG}
fi
/bin/rm ${MOX_AUTH_CONFIG}.$$
/bin/rm ${MOX_OIO_CONFIG}.$$



# Clean up temporary files
if [ -n "$NODEBUG" ]
then
	/bin/echo "Removing temporary files: /tmp/expect[137] ${CERTIFICATE_PKCS12} ${PUBLIC_KEY}"
	/bin/rm  -f /tmp/expect[137] ${CERTIFICATE_PKCS12} ${PUBLIC_KEY}
fi



if [ -z "$NODEBUG" ]
then
	/bin/echo -e "\n\n\nDEBUG is on...\nTo execute, set NODEBUG, i.d.:\nNODEBUG=x ${0}\n"
fi

# Vim: set all laststatus=2 statusline=Current\ File:\ %F :
