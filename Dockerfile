FROM golang:1.9.4-stretch
MAINTAINER schumyhaojl@126.com

ENV DEBIAN_FRONTEND noninteractive

ENV VERSION 9.0.4
ENV BUILD 11
ENV SIG c2514751926b4512b076cc82f959763f

ENV JAVA_HOME /usr/lib/jvm/java-${VERSION}-oracle

RUN apt-get update && apt-get install ca-certificates curl \
	    -y --no-install-recommends && \
	curl --silent --location --retry 3 --cacert /etc/ssl/certs/GeoTrust_Global_CA.pem \
	    --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
	    http://download.oracle.com/otn-pub/java/jdk/"${VERSION}"+"${BUILD}"/"${SIG}"/jdk-"${VERSION}"_linux-x64_bin.tar.gz \
	    | tar xz -C /tmp && \
	mkdir -p /usr/lib/jvm && mv /tmp/jdk-${VERSION} "${JAVA_HOME}" && \
	apt-get autoclean && apt-get --purge -y autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1 && \
	update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1 && \
	update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1 && \
	update-alternatives --set java "${JAVA_HOME}/bin/java" && \
	update-alternatives --set javaws "${JAVA_HOME}/bin/javaws" && \
	update-alternatives --set javac "${JAVA_HOME}/bin/javac"

RUN go get -d -u github.com/google/battery-historian/...
WORKDIR /go/src/github.com/google/battery-historian
RUN go run setup.go

EXPOSE 9999

COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]