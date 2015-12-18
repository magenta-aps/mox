Servlet compilation and deployment
==================================

The servlet depends on two modules (../modules/json and ../modules/spreadsheet) that can be compiled to jar files with Maven.
The pom.xml file has been set up, so just execute "mvn package" in each module folder, and the jars are compiled. There's even a maven-archive.sh script that puts the compilation results into your local maven repository, so that other modules can find it when depending. So: For each of the modules, run maven-archive.sh to compile the module and put it in the local repo. Some of them depend on the json module, so run that first.

The servlet can then be compiled with maven as well. "mvn package" should create a servlet .war file that will contain the dependencies and can be uploaded to the server. On the server, copy the war file to the servlets folder with tomcat running, and navigate to <servername>/mox/DocumentUpload in a browser
