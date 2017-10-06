#!/bin/bash

# This script install all builded artifact into 
# a Nuxeo based image :
#   * JAR artifacts in `artifacts` are copied into the Nuxeo `bundles` directory
#   * Nuxeo Package in `marketplace` is installed thru mp-install
#   * `nuxeo.conf` file is appended to regular nuxeo.conf
#

if [ "$(ls -A /build/artifacts 2>/dev/null)" ]; then
	echo "---> Copying JAR artifacts in bundles directory"  
	cp -v /build/artifacts/*.jar $NUXEO_HOME/nxserver/bundles
fi


if [ -f /build/nuxeo.conf ]; then
	echo "---> Copying nuxeo.conf"  
	cp -v /build/nuxeo.conf /docker-entrypoint-init.d/
fi

if [ -f /connect.properties ]; then
  echo "---> Found connect.properties file"  
  . /connect.properties

  if [ -n "$NUXEO_CONNECT_USERNAME" -a -n "$NUXEO_CONNECT_PASSWORD" -a -n "$NUXEO_STUDIO_PROJECT" ]; then  
    echo "---> Configuring connect credentials"
    /docker-entrypoint.sh nuxeoctl register $NUXEO_CONNECT_USERNAME $NUXEO_STUDIO_PROJECT dev openshift $NUXEO_CONNECT_PASSWORD
  fi

else 
  echo "---> No connect.properties found"
fi

if [ "$(ls -A /build/marketplace 2>/dev/null)" ]; then
  
  PACKAGES=$(ls -A /build/marketplace)
  if [ -n $PACKAGE ]; then
	  echo "---> Found package $PACKAGE"
	  echo "---> Installing Nuxeo Package for project from $LOCAL_SOURCE_DIR/$NUXEO_PACKAGE"  
	  /docker-entrypoint.sh nuxeoctl mp-init
	  /docker-entrypoint.sh $NUXEO_HOME/bin/nuxeoctl mp-install $PACKAGE
  else
  	  echo "---> No Nuxeo Package found"
  fi
fi