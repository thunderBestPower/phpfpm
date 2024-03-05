FROM php:8.2-fpm

ENV MAX_UPLOAD_SIZE 2M
ENV POST_MAX_SIZE 8M
# https://xdebug.org/docs/all_settings#start_with_request
ENV ENABLE_XDEBUG no
# Off o debug https://xdebug.org/docs/all_settings#mode
ENV ENABLE_MODE debug

WORKDIR /
RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl debconf git apt-transport-https apt-utils \
    build-essential locales acl mailutils wget zip unzip \
    gnupg gnupg1 gnupg2 \
    supervisor libpq-dev libpng-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh \
    && docker-php-ext-install opcache pdo_pgsql gd zip intl\
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
COPY /resources/v11.1.4fp4a_linuxx64_dsdriver.tar.gz /opt/ibm
WORKDIR /opt/ibm

#RUN tar -xvf v11.1.4fp4a_linuxx64_dsdriver.tar.gz
#WORKDIR /opt/ibm/dsdriver
#RUN chmod 755 installDSDriver
#RUN ksh installDSDriver
#RUN wget https://pecl.php.net/get/ibm_db2-2.0.8.tgz
#RUN tar -xvf ibm_db2-2.0.8.tgz
#RUN cd ibm_db2-2.0.8
#RUN phpize --clean
#RUN phpize
#RUN ./configure --enable-debug -with-IBM_DB2=/opt/ibm/dsdriver
#RUN make clean
#RUN make
#RUN make install
#RUN echo "extension=ibm_db2.so" >> $PHP_INI_DIR/php.ini

RUN tar -xvf v11.1.4fp4a_linuxx64_dsdriver.tar.gz
WORKDIR /opt/ibm/dsdriver
RUN phpize --clean
RUN phpize
RUN ./configure --enable-debug -with-IBM_DB2=/opt/ibm/dsdriver
RUN make clean
RUN make
RUN make install
RUN echo "extension=ibm_db2.so" >> $PHP_INI_DIR/php.ini

RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN mkdir /app
WORKDIR /app

RUN mkdir -p var/log \
    && chmod 777 var/log \
    && chown root:www-data var/log

RUN chmod g+w /usr/local/etc/php/conf.d

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
