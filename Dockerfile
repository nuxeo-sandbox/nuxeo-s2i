FROM nuxeo/nuxeo:9.10
MAINTAINER Damien Metzler <dmetzler@nuxeo.com>

ENV BUILDER_VERSION 1.0
ENV MAVEN_VERSION=3.5.4
ENV NODE_VERSION=6.14.4
ENV STI_SCRIPTS_PATH=/usr/libexec/s2i

LABEL io.k8s.description="Platform for building and running Nuxeo based applications" \
      io.k8s.display-name="Nuxeo S2i 9.10" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,nuxeo,nuxeo910" \
      io.openshift.s2i.scripts-url="image://$STI_SCRIPTS_PATH" \
      io.openshift.s2i.destination="/opt/s2i/destination"


USER root

# First install Maven
RUN (curl -v https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn && \
    mkdir -p /home/nuxeo/.m2 && \
    mkdir -p /opt/s2i/destination && \
# Then needed tools for Nuxeo build (ie npm & friends)
    curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends \
     nodejs \
     build-essential && \
    npm cache clean -f && \
	  npm install -g n  && \
	  n v${NODE_VERSION} && \
	  ln -sf /usr/local/n/versions/node/${NODE_VERSION}/bin/node /usr/bin/node  && \
    npm install -g npm@latest && \
    npm install -g gulp grunt grunt-cli polymer-cli bower yo && \
    rm -rf /var/lib/apt/lists/*

ADD ./contrib/settings.xml /opt/nuxeo/server/.m2/
ADD ./contrib/install.sh /build/install.sh


RUN mkdir -p /opt/s2i/destination && \
    chown -R 1000:0 /opt/s2i/destination && \
    chmod -R g+rwX /opt/s2i/destination && \
    chown -R 1000:0 /home/nuxeo && \
    chmod -R g+rwX /home/nuxeo && \
    mkdir -p /build/artifacts && \
    mkdir -p /build/marketplace && \
    chown -R 1000:0 /build/ && \
    chmod -R g+rwX /build/ && \
    chmod -R a+rwX /opt/nuxeo/server/.m2/



COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# This default user is created in the openshift/base-centos7 image
USER 1000:0

RUN git clone https://github.com/nuxeo/nuxeo && \
    cd nuxeo && git checkout 9.10 && \
    mvn install -fae -DskipTests -s $HOME/.m2/settings.xml || \
    cd .. && rm -rf nuxeo


CMD ["/usr/libexec/s2i/usage"]
