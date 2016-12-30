FROM helterscelter/base:oracle-java8

MAINTAINER Helter Scelter


ENV KAFKA_VERSION="0.10.1.0" SCALA_VERSION="2.11"
ENV KAFKA_HOME /opt/kafka
ENV PATH ${PATH}:${KAFKA_HOME}/bin

# zookeeper service to connect to
ENV KAFKA_ZOOKEEPER_CONNECT zk:2181

# location of the spool files
ENV KAFKA_LOG_DIR /kafka

# location of the log4j files
ENV LOG_DIR /var/log/kafka

# download and expand kafka from one of the apache mirrors into /opt 
RUN wget --progress=dot:mega -O - \
    $( wget -q -O -  https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r '.preferred|rtrimstr("/")' )/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
    | tar xzf - -C /opt; \
    ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME}





# create the kafka user/home/group/directories
RUN groupadd kafka; \
    useradd --gid kafka --home-dir /home/kafka --create-home --shell /bin/bash kafka; \
    mkdir -p ${LOG_DIR} ${KAFKA_LOG_DIR} ${KAFKA_HOME}; \
    chown -RL kafka:kafka ${LOG_DIR} ${KAFKA_LOG_DIR} ${KAFKA_HOME} 

# add the kafka supervisord template to the system supervisor config location
ADD supervisor /etc/supervisor

# configure kafka to run under supervisord
RUN /usr/bin/template.sh /etc/supervisor/templates/kafka.conf.templ /etc/supervisor/conf.d/kafka.conf KAFKA ${KAFKA_HOME}

# configure the kafka instance
ADD config ${KAFKA_HOME}/config
# add the wrapper script to start kafka.  This takes care of expanding the server.properties.template for runtime settings into server.properties
ADD bin ${KAFKA_HOME}/bin
# this sets up the build-time variable expansion.  the start-kafka.sh takes care of run-time variable expansion
RUN /usr/bin/template.sh ${KAFKA_HOME}/config/server.properties.templ ${KAFKA_HOME}/config/server.properties.template \
    && rm ${KAFKA_HOME}/config/server.properties.templ



# declare the kafka volume to store logs/spool
VOLUME [ "${KAFKA_LOG_DIR}", "${LOG_DIR}" ]

# launch supervisord when this container starts
CMD ["supervisord","-c","/etc/supervisor/supervisord.conf"]


