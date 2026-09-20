FROM php:7.4-fpm

ENV MAX_UPLOAD_SIZE=2M
ENV POST_MAX_SIZE=8M
ENV ENABLE_XDEBUG=0
ENV DISPLAY_ERRORS=0

WORKDIR /
RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano curl debconf git apt-transport-https apt-utils \
    build-essential locales acl mailutils wget zip unzip \
    libmagickwand-dev imagemagick ghostscript \
    gnupg gnupg1 gnupg2 ffmpeg \
    supervisor libpq-dev libpng-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh \
    && docker-php-ext-install opcache pdo_mysql gd zip intl xmlrpc \
    && pecl install redis-5.1.1 \
    && pecl install igbinary \
    && pecl install xdebug-2.9.0 \
    && pecl install apcu \
    && pecl install imagick \
    && docker-php-ext-enable redis igbinary xdebug apcu imagick \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml

# Quello di produzione, non quello di sviluppo: con il secondo un fatale che
# succede prima che il framework si avvii finisce in chiaro nella risposta HTTP.
# Chi sviluppa riaccende gli errori a video con DISPLAY_ERRORS=1.
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY resources/ /resources/
WORKDIR /resources
COPY /resources/php.ini $PHP_INI_DIR/conf.d/
RUN cat /resources/www.conf >> /usr/local/etc/php-fpm.d/www.conf
COPY /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# var/ appartiene a www-data, che e' l'utente dei worker di php-fpm e quello con
# cui girano i comandi schedulati. Le cartelle vanno create qui: supervisord ci
# scrive il proprio log e il pidfile, quindi se mancano non parte nemmeno.
RUN mkdir -p /app/var/log /app/var/cache \
    && chown -R www-data:www-data /app/var
WORKDIR /app

RUN chmod g+w /usr/local/etc/php/conf.d

# Niente VOLUME ["/app"]: con il builder vecchio faceva scartare in silenzio le
# modifiche che le immagini figlie fanno dentro /app - a partire dalla loro
# chmod - e l'immagine usciva a 755 di root, con i comandi schedulati che non
# riuscivano piu' a scrivere. In piu' ogni container senza bind mount su /app si
# creava un volume anonimo che restava li'. I mount li decide il compose.

EXPOSE 9000
CMD ["bash", "/resources/entrypoint.sh"]
