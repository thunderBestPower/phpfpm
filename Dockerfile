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
    ksh freetds-bin freetds-dev freetds-common \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ \
    && docker-php-ext-install opcache pdo_pgsql pdo_dblib gd zip intl\
    && pecl install redis \
    && pecl install igbinary \
    && pecl install xdebug \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu

ENV ACCEPT_EULA=Y

RUN curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18
RUN apt-get install unixodbc unixodbc-dev -y
RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv
RUN docker-php-ext-enable sqlsrv pdo_sqlsrv


RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
ADD /resources/* /resources/
WORKDIR /resources
COPY /resources/php.ini $PHP_INI_DIR/conf.d/
RUN cat /resources/www.conf >> /usr/local/etc/php-fpm.d/www.conf
COPY /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN mkdir /app
WORKDIR /app

RUN chmod g+w /usr/local/etc/php/conf.d

RUN usermod -g www-data -g sudo root
USER root
#RUN useradd -m -r -u 1000 -g www-data -g sudo -g root appuser
#USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
