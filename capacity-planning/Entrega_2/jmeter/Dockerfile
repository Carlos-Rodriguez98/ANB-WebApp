# Dockerfile - imagen ligera para JMeter CLI (no GUI) con Java 17
FROM eclipse-temurin:17-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive
ARG JMETER_VERSION=5.6.3
ENV JMETER_HOME=/opt/jmeter
ENV PATH=${JMETER_HOME}/bin:${PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Descargar y desplegar JMeter
RUN mkdir -p /opt && \
    wget -qO /tmp/apache-jmeter.zip "https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip" && \
    unzip -q /tmp/apache-jmeter.zip -d /opt && \
    mv /opt/apache-jmeter-${JMETER_VERSION} ${JMETER_HOME} && \
    rm -rf /tmp/apache-jmeter.zip && \
    chmod -R a+rX ${JMETER_HOME}

# Usuario no-root y directorios
RUN useradd -m -d /home/jmeter -s /bin/bash jmeter && \
    mkdir -p /home/jmeter/.java/.userPrefs /home/jmeter/report && \
    chown -R jmeter:jmeter /home/jmeter ${JMETER_HOME}

USER jmeter
WORKDIR /home/jmeter

# Cambiar ENTRYPOINT por CMD para permitir override
CMD ["tail", "-f", "/dev/null"]