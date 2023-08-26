FROM php:7.4-fpm

ENV MAX_UPLOAD_SIZE 2M
ENV POST_MAX_SIZE 8M
ENV ENABLE_XDEBUG 0
ENV SAP_HANA_NAME hana
ENV SAP_HANA_IP 192.168.1.1
ENV SAP_HANA_PORT 30015

WORKDIR /
RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl debconf git apt-transport-https apt-utils \
    build-essential locales acl mailutils wget zip unzip \
    gnupg gnupg1 gnupg2 \
    supervisor libpq-dev libpng-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh freetds-bin freetds-dev freetds-common \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ \
    && docker-php-ext-install opcache pdo_pgsql pdo_dblib gd zip intl xmlrpc \
    && pecl install redis-5.1.1 \
    && pecl install igbinary \
    && pecl install xdebug-2.9.0 \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu

RUN apt-get install unixodbc unixodbc-dev -y \
 && docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
 && docker-php-ext-install pdo_odbc

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
ADD /resources/* /resources/
WORKDIR /resources

#Installazione di SAP client
RUN wget https://storage.googleapis.com/docker_sap_hana/hanaclient-latest-linux-x64.tar.gz
RUN tar xvzf hanaclient-latest-linux-x64.tar.gz
RUN chmod +x /resources/client/hdbinst
RUN chmod +x /resources/client/hdbsetup
RUN chmod +x /resources/client/hdbuninst
RUN chmod +x /resources/client/instruntime/sdbrun
RUN mkdir -p /opt/sap/hdbclient
RUN chown 777 /opt/sap/hdbclient
RUN /resources/client/./hdbinst -p=/home/appuser/sap/hdbclient -a client

COPY /resources/php.ini $PHP_INI_DIR/conf.d/
RUN cat /resources/www.conf >> /usr/local/etc/php-fpm.d/www.conf
COPY /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN chmod 777 /etc/odbc.ini

# Devo modificare un open SSL per la connessione API a SAP
RUN sed -i 's/TLSv1.2/TLSv1/g' /etc/ssl/openssl.cnf

RUN mkdir /app
WORKDIR /app

RUN chmod g+w /usr/local/etc/php/conf.d
#RUN useradd -m -r -u 1000 -g www-data -g sudo -g root appuser
#USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]