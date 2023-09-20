FROM php:8.1-fpm

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
    && docker-php-ext-install opcache pdo_pgsql gd zip intl\
    && pecl install redis-5.3.7 \
    && pecl install igbinary \
    && pecl install xdebug-3.1.3 \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu

# Aggiungo i repository per scaricare
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Aggiorna il sistema
RUN apt-get update && apt-get install -y

# VEDi README per le versioni
# Ho installato odbc
RUN apt-get install unixodbc unixodbc-dev -y
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18
# VEdi README
RUN pecl install sqlsrv-5.11.1
RUN pecl install pdo_sqlsrv-5.11.1

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

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
