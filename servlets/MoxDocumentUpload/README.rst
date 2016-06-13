Servlet compilation and deployment
==================================

The servlet depends on two modules (../modules/json and ../modules/spreadsheet)
that can be compiled to jar files with Maven.
The pom.xml file has been set up, so just execute "mvn package" in each module
folder, and the jars are compiled.

Use the compile-java.sh script in the root folder to recompile/reinstall all
of these dependencies.

The servlet can then be compiled with maven as well. "mvn package" should
create a servlet .war file that will contain the dependencies and can be
uploaded to the server. On the server, copy the war file to the servlets
folder with Tomcat running, and navigate to
http://<servername>/MoxDocumentUpload/MoxDocumentUpload in a browser
