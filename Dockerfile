FROM php:8.4-fpm

ENV MAX_UPLOAD_SIZE=2M
ENV POST_MAX_SIZE=8M
# https://xdebug.org/docs/all_settings#start_with_request
ENV ENABLE_XDEBUG=no
# Off o debug https://xdebug.org/docs/all_settings#mode
ENV ENABLE_MODE=debug

WORKDIR /
RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl debconf git apt-transport-https apt-utils \
    build-essential locales acl mailutils wget zip unzip fish \
    gnupg gnupg1 gnupg2 ffmpeg \
    supervisor libpq-dev libjpeg-dev libpng-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh freetds-bin freetds-dev freetds-common \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ \
    && docker-php-ext-install opcache pdo_pgsql pdo_dblib gd zip intl ftp \
    && pecl install redis \
    && pecl install igbinary \
    && pecl install xdebug \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu

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
# Le librerie del dsdriver servono sia per compilare che a runtime
ENV LD_LIBRARY_PATH=/opt/ibm/dsdriver/lib

# ibm_db2 2.3.1: la 2.2.0 usa php_strtolower()/php_strtoupper(),
# rimosse da PHP 8.3, quindi non compila piu' su PHP 8.4
ENV IBM_DB2_VERSION=2.3.1
RUN wget -q https://pecl.php.net/get/ibm_db2-$IBM_DB2_VERSION.tgz \
    && tar -xzf ibm_db2-$IBM_DB2_VERSION.tgz \
    && cd ibm_db2-$IBM_DB2_VERSION \
    && phpize \
    && ./configure --with-IBM_DB2=/opt/ibm/dsdriver \
    && make -j"$(nproc)" \
    && make install \
    && cd .. \
    && rm -rf ibm_db2-$IBM_DB2_VERSION ibm_db2-$IBM_DB2_VERSION.tgz \
    && docker-php-ext-enable ibm_db2


RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN mkdir /app
WORKDIR /app

RUN chmod g+w /usr/local/etc/php/conf.d

# Definiamo degli ARG con valori di default, che potrai sovrascrivere nel docker-compose
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" appgroup \
    && useradd -m -l -u "${UID}" -g appgroup appuser \
    && usermod -aG www-data appuser

# Permettiamo ad appuser di gestire le configurazioni PHP (necessario per il tuo entrypoint)
RUN chown -R appuser:appgroup /usr/local/etc/php/conf.d \
    && chmod -R 775 /usr/local/etc/php/conf.d \
    && chown -R appuser:appgroup /app

# Se l'entrypoint deve modificare anche il php.ini principale:
RUN chown appuser:appgroup /usr/local/etc/php/php.ini

RUN usermod -s /usr/bin/fish appuser

USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
