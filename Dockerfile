FROM debian:stretch
MAINTAINER Christian Simon <mail@christiansimon.eu>

ENV APP_USER pm15
ENV APP_USER_ID 801
ENV APP_HOME /opt/pm15

ENV LANG en_US.UTF-8
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV JAVA_EXE ${JAVA_HOME}/bin/java

ENV PM15_VERSION 1.1.2

# Install tools and libs
RUN apt-get update && apt-get install -y apt-utils && apt-get install -y \
    curl \
    tzdata \
    locales \
    apt-transport-https \
    gnupg \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set Locale to UTF-8
RUN ( echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen ) \
    && locale-gen

# Set timezone
RUN ( echo "Europe/Berlin" > /etc/timezone ) \
    && ln -fs /usr/share/zoneinfo/`cat /etc/timezone` /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

# Install Java
RUN ( echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list ) \
    && apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
    && apt-get update -y \
    && ( echo "yes" | apt-get install -y oracle-java8-installer oracle-java8-set-default ) \
    && rm -rf /var/lib/apt/lists/*

# Add dedicated user
RUN groupadd -r --gid "${APP_USER_ID}" "${APP_USER}" \
    && useradd -r --uid "${APP_USER_ID}" -g "${APP_USER}" -m "${APP_USER}" \
    && mkdir -p "${APP_HOME}" \
    && chown "${APP_USER}":"${APP_USER}" "${APP_HOME}"

USER ${APP_USER}
WORKDIR ${APP_HOME}

# Download appserver and prepare directories
RUN mkdir ${APP_HOME}/media \
    && mkdir ${APP_HOME}/logs \
    && mkdir ${APP_HOME}/conf \
    && curl -L -H "Accept: application/octet-stream" https://github.com/metaxmx/pm15/releases/download/v${PM15_VERSION}/pm15-${PM15_VERSION}.zip -o pm15-${PM15_VERSION}.zip \
    && unzip pm15-${PM15_VERSION}.zip \
    && rm pm15-${PM15_VERSION}.zip \
    && mv pm15-${PM15_VERSION} appserver \
    && rm -r ${APP_HOME}/appserver/share \
    && ln -s ${APP_HOME}/conf/instance.conf ${APP_HOME}/appserver/conf/instance.conf \
    && ln -s ${APP_HOME}/logs ${APP_HOME}/appserver/logs

VOLUME ["${APP_HOME}/media", "${APP_HOME}/logs", "${APP_HOME}/conf"]

# App Server Port
EXPOSE 9009

ENTRYPOINT ["/opt/pm15/appserver/bin/pm15"]

CMD ["-java-home", "/usr/lib/jvm/java-8-oracle", "-Dhttp.port=9009", "-Dplay.evolutions.db.default.autoApply=true"]