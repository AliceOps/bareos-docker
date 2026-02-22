FROM ubuntu:noble

LABEL maintainer="local"

ENV DEBIAN_FRONTEND=noninteractive
ENV BAREOS_KEY=https://download.bareos.org/current/xUbuntu_24.04/Release.key
ENV BAREOS_REPO=https://download.bareos.org/current/xUbuntu_24.04/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -qq \
 && apt-get -qq -y install --no-install-recommends ca-certificates curl tzdata gnupg \
 && curl -fsSL "$BAREOS_KEY" -o /tmp/bareos.key \
 && apt-key --keyring /etc/apt/trusted.gpg.d/bareos-keyring.gpg add /tmp/bareos.key \
 && echo "deb $BAREOS_REPO /" > /etc/apt/sources.list.d/bareos.list \
 && apt-get update -qq \
 && apt-get install -qq -y --no-install-recommends bareos-webui \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN a2enmod proxy_fcgi setenvif rewrite \
 && a2enconf php8.3-fpm

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh

RUN tar czf /bareos-webui.tgz /etc/bareos-webui

EXPOSE 80

VOLUME /etc/bareos-webui

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
