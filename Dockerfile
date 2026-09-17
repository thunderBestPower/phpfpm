FROM php:8.2-fpm

ENV MAX_UPLOAD_SIZE=2M
ENV POST_MAX_SIZE=8M
# default di PHP, sovrascrivibile dal docker-compose del progetto
ENV MEMORY_LIMIT=128M
# processi php-fpm, cioè richieste servite in parallelo
ENV PM_MAX_CHILDREN=5
# https://xdebug.org/docs/all_settings#start_with_request
ENV ENABLE_XDEBUG=no
# Off o debug https://xdebug.org/docs/all_settings#mode
ENV ENABLE_MODE=debug

RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl fish git apt-utils \
    build-essential locales acl mailutils wget zip unzip \
    gnupg ffmpeg \
    pdftk-java \
    supervisor libpq-dev libjpeg-dev libpng-dev libwebp-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh freetds-bin freetds-dev freetds-common \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install opcache pdo_pgsql pdo_dblib gd exif zip intl \
    && pecl install redis \
    && pecl install igbinary \
    && pecl install xdebug \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

ENV ACCEPT_EULA=Y

# Driver Microsoft SQL Server per Debian 13 (base di php:8.2-fpm):
# il repo ubuntu/20.04 non passa più la verifica della firma di apt.
# sqlsrv fissato a 5.12.0: dalla 5.13 serve PHP >= 8.3
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft-2025.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl -fsSL https://packages.microsoft.com/config/debian/13/prod.list -o /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y msodbcsql18 unixodbc unixodbc-dev \
    && pecl install sqlsrv-5.12.0 pdo_sqlsrv-5.12.0 \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen

COPY resources/ /resources/
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && cp /resources/php.ini "$PHP_INI_DIR/conf.d/" \
    && cat /resources/www.conf >> /usr/local/etc/php-fpm.d/www.conf \
    && cp /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Permessi: appuser resta con uid 1999 e gli stessi gruppi delle build precedenti,
# così i volumi dei progetti esistenti non cambiano proprietario.
# Con il gruppo root e g+w su conf.d l'entrypoint può modificare php.ini e rimuovere xdebug.
RUN groupadd docker \
    && useradd -m -r -u 1999 -s /usr/bin/fish appuser \
    && usermod -aG sudo,docker,www-data,root appuser \
    && chmod g+w /usr/local/etc/php/conf.d \
    && mkdir /app \
    && chown appuser /app

WORKDIR /app
USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
