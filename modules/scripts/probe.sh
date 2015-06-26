#!/bin/bash
SOURCE=$1
TOMCAT_WEBAPPS=$3

pushd $SOURCE
if [ -d psi-probe ]; then
	pushd psi-probe && git pull
else
	git clone https://github.com/psi-probe/psi-probe && pushd psi-probe
fi
mvn package -Dmaven.test.skip=true
cp web/target/probe.war $TOMCAT_WEBAPPS/
popd
popd
