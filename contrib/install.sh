#!/bin/bash

# This script install all builded artifact into 
# a Nuxeo based image :
#   * JAR artifacts in `artifacts` are copied into the Nuxeo `bundles` directory
#   * Nuxeo Package in `marketplace` is installed thru mp-install
#   * `nuxeo.conf` file is appended to regular nuxeo.conf
#

function fixRights() {
  dir=$1
  mkdir -p $dir \
  && chgrp -fR 0 $dir \
  && chmod -fR g+rwX $dir
}


echo "---> Installing what has been built"
find /build

if [ "$(ls -A /build/artifacts 2>/dev/null)" ]; then
	echo "---> Copying JAR artifacts in bundles directory"  
	cp -v /build/artifacts/*.jar $NUXEO_HOME/nxserver/bundles
fi


if [ -f /build/nuxeo.conf ]; then
	echo "---> Copying nuxeo.conf"  
	cp -v /build/nuxeo.conf /docker-entrypoint-init.d/
fi

if [ -f /opt/nuxeo/connect/connect.properties ]; then
  echo "---> Found connect.properties file"  
  . /opt/nuxeo/connect/connect.properties

  if [ -n "$NUXEO_CONNECT_USERNAME" -a -n "$NUXEO_CONNECT_PASSWORD" -a -n "$NUXEO_STUDIO_PROJECT" ]; then  
    echo "---> Configuring connect credentials"
    /docker-entrypoint.sh nuxeoctl register $NUXEO_CONNECT_USERNAME $NUXEO_STUDIO_PROJECT dev openshift $NUXEO_CONNECT_PASSWORD

    echo "---> Installing hotfixes"
    /docker-entrypoint.sh nuxeoctl mp-hotfix
  fi

else 
  echo "---> No connect.properties found"
fi

if [ "$(ls -A /build/marketplace 2>/dev/null)" ]; then
  PACKAGE=$(ls -A /build/marketplace)  
  echo "---> Found package $PACKAGE"
  echo "---> Installing Nuxeo Package for project from /build/marketplace"  
  /docker-entrypoint.sh nuxeoctl mp-init
  /docker-entrypoint.sh $NUXEO_HOME/bin/nuxeoctl mp-install /build/marketplace/$PACKAGE
else
    echo "---> No Nuxeo Package found"
fi

if [ -n "$NUXEO_PACKAGES" ]; then
  echo "---> Installing additional packages $NUXEO_PACKAGES"
  /docker-entrypoint.sh $NUXEO_HOME/bin/nuxeoctl mp-install $NUXEO_PACKAGES
fi

echo "---> Resetting image configuration 0"
#rm -f $NUXEO_HOME/configured
echo "---> Resetting image configuration 1"
#rm -f /etc/nuxeo/nuxeo.conf
echo "---> Resetting image configuration 2"
fixRights /var/lib/nuxeo/data
echo "---> Resetting image configuration 3"
fixRights /var/log/nuxeo
echo "---> Resetting image configuration 4"
fixRights /var/run/nuxeo
echo "---> Resetting image configuration 5"
fixRights /docker-entrypoint-initnuxeo.d
