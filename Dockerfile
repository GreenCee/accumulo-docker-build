FROM ubuntu:bionic

RUN apt-get update
RUN apt-get install -q -y git openjdk-11-jdk make g++ wget libboost1.65-dev

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

ARG MAVEN_VERSION=3.6.3
ARG THRIFT_VERSION=0.12.0

ENV APACHE_DIST_URLS \
  https://www.apache.org/dyn/closer.cgi?action=download&filename= \
# if the version is outdated (or we're grabbing the .asc file), we might have to pull from the dist/archive :/
  https://www-us.apache.org/dist/ \
  https://www.apache.org/dist/ \
  https://archive.apache.org/dist/

RUN set -eux; \
  download() { \
    local f="$1"; shift; \
    local distFile="$1"; shift; \
    local success=; \
    local distUrl=; \
    for distUrl in $APACHE_DIST_URLS; do \
      if wget -nv -O "$f" "$distUrl$distFile"; then \
        success=1; \
        break; \
      fi; \
    done; \
    [ -n "$success" ]; \
  }; \
  \
  download "maven.tar.gz" "maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"; \
  download "thrift.tar.gz" "thrift/$THRIFT_VERSION/thrift-$THRIFT_VERSION.tar.gz";

#TODO check hash
  
RUN tar xvzf maven.tar.gz -C /tmp/
RUN mv /tmp/apache-maven-$MAVEN_VERSION /opt/apache-maven

RUN tar xvzf thrift.tar.gz -C /tmp/
RUN cd /tmp/thrift-$THRIFT_VERSION; \
    ./configure --disable-libs; \
    make; \
    make install; \
    cd ..; rm -rf thrift-$THRIFT_VERSION


ADD ./runIT /opt/accumulo-build/bin/

ENV PATH "$PATH:/opt/apache-maven/bin:/opt/accumulo-build/bin"



