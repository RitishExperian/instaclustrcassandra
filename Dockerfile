FROM debian:jessie

COPY dagi /usr/local/bin/

RUN echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list

# common set of packages shared by all
RUN dagi 	python libpython-stdlib  python-minimal python-support python-pip \
			ntp \
			ca-certificates \
			netcat \
			curl \
			libjemalloc1

RUN echo "deb http://www.apache.org/dist/cassandra/debian 311x main" > /etc/apt/sources.list.d/cassandra.sources.list

RUN curl https://www.apache.org/dist/cassandra/KEYS | apt-key add -

RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-key A278B781FE4B2BDA

ENV PATH /opt/bin:$PATH

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
    && echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >> /etc/apt/sources.list.d/webupd8team-java.list \
    && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >> /etc/apt/sources.list.d/webupd8team-java.list \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

RUN dagi oracle-java8-installer \
    && rm -r /var/cache/oracle-jdk8-installer

COPY local_policy.jar US_export_policy.jar /usr/lib/jvm/java-8-oracle/jre/lib/security/

COPY install-cassandra /tmp/install-cassandra


#RUN /tmp/install-cassandra @@APACHE_CASSANDRA_VERSION@@ @@CUSTOM_BUILD@@
RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra

ENV CASSANDRA_VERSION 3.11.1

ENV CASSANDRA_CONFIG /etc/cassandra

RUN /tmp/install-cassandra "$CASSANDRA_VERSION"

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

RUN mkdir -p /var/lib/cassandra "$CASSANDRA_CONFIG" \
        && chown -R cassandra:cassandra /var/lib/cassandra "$CASSANDRA_CONFIG" \
        && chmod 777 /var/lib/cassandra "$CASSANDRA_CONFIG"
VOLUME /var/lib/cassandra

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

USER 999:999

CMD ["cassandra", "-f","-R"]
