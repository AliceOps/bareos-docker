FROM ubuntu:noble

LABEL maintainer="local"

ENV DEBIAN_FRONTEND=noninteractive
ENV BAREOS_KEY=https://download.bareos.org/current/xUbuntu_24.04/Release.key
ENV BAREOS_REPO=https://download.bareos.org/current/xUbuntu_24.04/
ENV BAREOS_DPKG_CONF="bareos-database-common bareos-database-common"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -qq \
 && apt-get -qq -y install --no-install-recommends ca-certificates curl tzdata gnupg \
 && curl -fsSL "$BAREOS_KEY" -o /tmp/bareos.key \
 && apt-key --keyring /etc/apt/trusted.gpg.d/bareos-keyring.gpg add /tmp/bareos.key \
 && echo "deb $BAREOS_REPO /" > /etc/apt/sources.list.d/bareos.list \
 && echo "${BAREOS_DPKG_CONF}/dbconfig-install boolean false" | debconf-set-selections \
 && echo "${BAREOS_DPKG_CONF}/install-error select ignore" | debconf-set-selections \
 && echo "${BAREOS_DPKG_CONF}/database-type select pgsql" | debconf-set-selections \
 && echo "${BAREOS_DPKG_CONF}/missing-db-package-error select ignore" | debconf-set-selections \
 && echo 'postfix postfix/main_mailer_type select No configuration' | debconf-set-selections \
 && apt-get update -qq \
 && apt-get install -qq -y --no-install-recommends \
    bareos bareos-database-postgresql postgresql-client bareos-tools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY webhook-notify /usr/local/bin/webhook-notify
RUN chmod u+x /usr/local/bin/webhook-notify

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh

EXPOSE 9101

VOLUME /etc/bareos
VOLUME /var/lib/bareos

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/bareos-dir", "-u", "bareos", "-f"]
