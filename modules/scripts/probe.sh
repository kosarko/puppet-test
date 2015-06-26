#!/bin/bash
SOURCE=$1
TOMCAT_WEBAPPS=$3

pushd $SOURCE
git clone https://github.com/psi-probe/psi-probe && pushd psi-probe
mvn package
cp web/target/probe.war $TOMCAT_WEBAPPS/
popd
popd
