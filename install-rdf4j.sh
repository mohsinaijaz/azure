#!/bin/bash

# Update system
sudo apt-get update

# Install Java
sudo apt-get install -y default-jdk

# Install Tomcat
sudo apt-get install -y tomcat9

# Start Tomcat
sudo systemctl start tomcat9

# install unzip
sudo apt-get install -y unzip

# Download RDF4J Server
echo "Downloading RDF4J Server..."
wget -O "/var/lib/tomcat9/webapps/rdf4j-server.war" "https://repo1.maven.org/maven2/org/eclipse/rdf4j/rdf4j-http-server/3.7.2/rdf4j-http-server-3.7.2.war"

# Download RDF4J Workbench
echo "Downloading RDF4J Workbench..."
wget -O "/var/lib/tomcat9/webapps/rdf4j-workbench.war" "https://repo1.maven.org/maven2/org/eclipse/rdf4j/rdf4j-http-workbench/3.7.2/rdf4j-http-workbench-3.7.2.war"


# Create setenv.sh in Tomcat's bin directory
echo 'JAVA_OPTS="$JAVA_OPTS -Dorg.eclipse.rdf4j.appdata.basedir=/tmp"' | sudo tee /usr/share/tomcat9/bin/setenv.sh > /dev/null
echo 'export JAVA_OPTS' | sudo tee -a /usr/share/tomcat9/bin/setenv.sh > /dev/null
sudo chmod +x /usr/share/tomcat9/bin/setenv.sh

# Restart Tomcat to deploy RDF4J
sudo systemctl restart tomcat9
