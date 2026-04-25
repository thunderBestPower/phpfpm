FROM php:8.2-fpm

ENV MAX_UPLOAD_SIZE=2M
ENV POST_MAX_SIZE=8M
# https://xdebug.org/docs/all_settings#start_with_request
ENV ENABLE_XDEBUG=no
# Off o debug https://xdebug.org/docs/all_settings#mode
ENV ENABLE_MODE=debug

WORKDIR /
RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl fish debconf git apt-transport-https apt-utils \
    build-essential locales acl mailutils wget zip unzip \
    gnupg gnupg1 gnupg2 ffmpeg \
    supervisor libpq-dev libjpeg-dev libpng-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh freetds-bin freetds-dev freetds-common
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/
RUN docker-php-ext-install opcache pdo_pgsql pdo_dblib gd zip intl \
    && pecl install redis \
    && pecl install igbinary \
    && pecl install xdebug-3.1.6 \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu


# Correzione Driver Microsoft per Debian (non Ubuntu)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev

RUN pecl install sqlsrv-5.10.1 pdo_sqlsrv-5.10.1 \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv
# — Abilita il provider legacy di OpenSSL3 senza toccare il file di sistema —
# 1) Copia il tuo snippet immutato
#COPY resources/openssl-legacy.cnf /etc/ssl/openssl-legacy.cnf
#
## 2) Appendi l’include del cnf di sistema originale
#RUN printf '\n.include /etc/ssl/openssl.cnf\n' >> /etc/ssl/openssl-legacy.cnf
#
## 3) Esporta la variabile per tutti i processi
#ENV OPENSSL_CONF=/etc/ssl/openssl-legacy.cnf
#
## 4) Assicurati che PHP-FPM la erediti
#RUN echo "env[OPENSSL_CONF] = /etc/ssl/openssl-legacy.cnf" \
#    >> /usr/local/etc/php-fpm.d/www.conf
# ————————————————————————————————————————————————————————————————



RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
ADD /resources/* /resources/
WORKDIR /resources
COPY /resources/php.ini $PHP_INI_DIR/conf.d/
RUN cat /resources/www.conf >> /usr/local/etc/php-fpm.d/www.conf
COPY /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir /opt/ibm
COPY /resources/v11.5.4_linuxx64_dsdriver.tar.gz /opt/ibm
WORKDIR /opt/ibm

RUN tar -xvf v11.5.4_linuxx64_dsdriver.tar.gz
WORKDIR /opt/ibm/dsdriver
RUN chmod 755 installDSDriver
RUN ksh installDSDriver
RUN wget https://pecl.php.net/get/ibm_db2-2.2.0.tgz
RUN ls -al
RUN tar -xvf ibm_db2-2.2.0.tgz
RUN chmod -R 777 ibm_db2-2.2.0
WORKDIR /opt/ibm/dsdriver/ibm_db2-2.2.0

RUN ls -al
RUN pwd
RUN  phpize --clean
RUN  phpize
RUN  ./configure --enable-debug -with-IBM_DB2=/opt/ibm/dsdriver
RUN  make clean
RUN  make
RUN  make install
RUN  echo "extension=ibm_db2.so" >> $PHP_INI_DIR/php.ini


RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN mkdir /app
WORKDIR /app

RUN chmod g+w /usr/local/etc/php/conf.d

# Permessi
RUN groupadd docker
RUN useradd -m -r -u 1999 appuser
RUN usermod -aG sudo appuser
RUN usermod -aG docker appuser
RUN usermod -aG www-data appuser
RUN usermod -aG root appuser

USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh", "fish"]
