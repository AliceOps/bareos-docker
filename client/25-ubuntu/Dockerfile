FROM ubuntu:noble

LABEL maintainer="local"

ENV BAREOS_DAEMON_USER=bareos
ENV BAREOS_DAEMON_GROUP=bareos
ENV DEBIAN_FRONTEND=noninteractive
ENV BAREOS_KEY=https://download.bareos.org/current/xUbuntu_24.04/Release.key
ENV BAREOS_REPO=https://download.bareos.org/current/xUbuntu_24.04/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -qq \
 && apt-get -qq -y install --no-install-recommends ca-certificates curl tzdata gnupg gosu \
 && curl -fsSL "$BAREOS_KEY" -o /tmp/bareos.key \
 && apt-key --keyring /etc/apt/trusted.gpg.d/bareos-keyring.gpg add /tmp/bareos.key \
 && echo "deb $BAREOS_REPO /" > /etc/apt/sources.list.d/bareos.list \
 && apt-get update -qq \
 && apt-get install -qq -y --no-install-recommends \
    bareos-client postgresql-client bareos-tools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+x /docker-entrypoint.sh

RUN tar czf /bareos-fd.tgz /etc/bareos/bareos-fd.d

EXPOSE 9102

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/bareos-fd", "-f"]
