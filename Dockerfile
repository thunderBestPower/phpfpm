FROM php:8.4-fpm

ENV MAX_UPLOAD_SIZE=2M
ENV POST_MAX_SIZE=8M
# default di PHP, sovrascrivibile dal docker-compose del progetto
ENV MEMORY_LIMIT=128M
# https://xdebug.org/docs/all_settings#start_with_request
ENV ENABLE_XDEBUG=no
# Off o debug https://xdebug.org/docs/all_settings#mode
ENV ENABLE_MODE=debug

RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl git apt-utils \
    build-essential locales acl mailutils wget zip unzip fish \
    gnupg ffmpeg \
    supervisor libpq-dev libjpeg-dev libpng-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh \
    && docker-php-ext-install opcache pdo_pgsql gd zip intl ftp \
    && pecl install redis \
    && pecl install igbinary \
    && pecl install xdebug \
    && pecl install apcu \
    && docker-php-ext-enable redis igbinary xdebug apcu \
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

# Definiamo degli ARG con valori di default, che potrai sovrascrivere nel docker-compose
ARG UID=1000
ARG GID=1000

# appuser deve poter modificare conf.d dall'entrypoint (sed su php.ini, rimozione xdebug)
RUN groupadd -g "${GID}" appgroup \
    && useradd -m -l -u "${UID}" -g appgroup -s /usr/bin/fish appuser \
    && usermod -aG www-data appuser \
    && mkdir /app \
    && chown -R appuser:appgroup /usr/local/etc/php/conf.d /app \
    && chmod -R 775 /usr/local/etc/php/conf.d

WORKDIR /app
USER appuser

VOLUME ["/app"]

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
