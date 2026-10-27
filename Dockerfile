FROM php:8.4-fpm

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
# cartelle rese di appuser all'avvio (separate da spazio, solo sotto /app)
ENV FIX_PERMISSIONS_DIRS="/app/var/log /app/var/cache /app/resources"

RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl git apt-utils \
    build-essential locales acl mailutils wget zip unzip fish sudo \
    gnupg ffmpeg \
    supervisor libpq-dev libjpeg-dev libpng-dev libwebp-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh freetds-bin freetds-dev freetds-common \
    cups-client cups-bsd \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install opcache pdo_pgsql pdo_dblib gd exif zip intl ftp bcmath \
    && pecl install redis \
    && pecl install igbinary \
    && pecl install xdebug \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

ENV ACCEPT_EULA=Y

# Driver Microsoft SQL Server per Debian 13 (base di php:8.4-fpm)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft-2025.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl -fsSL https://packages.microsoft.com/config/debian/13/prod.list -o /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y msodbcsql18 unixodbc unixodbc-dev \
    && pecl install sqlsrv pdo_sqlsrv \
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
    && cp /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf \
    && install -o root -g root -m 755 /resources/fix-permissions.sh /usr/local/bin/fix-permissions

# Definiamo degli ARG con valori di default, che potrai sovrascrivere nel docker-compose
ARG UID=1000
ARG GID=1000

# appuser deve poter modificare conf.d dall'entrypoint (sed su php.ini, rimozione xdebug)
# gruppo lp per la stampante
RUN groupadd -g "${GID}" appgroup \
    && useradd -m -l -u "${UID}" -g appgroup -s /usr/bin/fish appuser \
    && usermod -aG www-data appuser \
    && usermod -aG lp appuser \
    && mkdir /app \
    && chown -R appuser:appgroup /usr/local/etc/php/conf.d /app \
    && chmod -R 775 /usr/local/etc/php/conf.d \
    && echo "appuser ALL=(root) NOPASSWD: /usr/local/bin/fix-permissions" > /etc/sudoers.d/fix-permissions \
    && chmod 440 /etc/sudoers.d/fix-permissions \
    && visudo -cf /etc/sudoers.d/fix-permissions

WORKDIR /app
USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
