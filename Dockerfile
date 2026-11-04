FROM php:8.4-fpm

ENV MAX_UPLOAD_SIZE=2M
ENV POST_MAX_SIZE=8M
ENV ENABLE_XDEBUG=0
ENV DISPLAY_ERRORS=0

WORKDIR /

# Gli header -dev, build-essential e g++ servono solo a compilare le estensioni
# qui sotto. Le librerie di runtime (libpng16, libjpeg62, libmagickwand...)
# arrivano come dipendenze di imagemagick, ffmpeg e degli stessi -dev.
RUN apt-get update \
    && apt-get install -y --no-install-recommends vim nano fish curl git apt-utils \
    build-essential locales acl mailutils wget zip unzip \
    libmagickwand-dev imagemagick ghostscript \
    gnupg ffmpeg \
    supervisor libpng-dev libjpeg-dev libfreetype6-dev libwebp-dev libssl-dev libcurl4-openssl-dev pkg-config libzip-dev libedit-dev zlib1g-dev libicu-dev g++ libxml2-dev \
    ksh \
    && docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp \
    && docker-php-ext-install -j"$(nproc)" opcache pdo_mysql gd exif zip intl bcmath \
    && pecl install redis igbinary xdebug apcu imagick \
    && docker-php-ext-enable redis igbinary xdebug apcu imagick \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

# Su trixie c'e' ImageMagick 7 e la policy di Debian i PDF non li blocca piu'.
# Il sed lo lascio nel caso tornino a bloccarli, e il grep fa fallire la build
# se resta un divieto sui PDF: senza, l'estrazione delle pagine si rompe muta.
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-*/policy.xml \
    && ! grep -E 'rights="none" pattern="[^"]*PDF' /etc/ImageMagick-*/policy.xml

# Quello di produzione, non quello di sviluppo: con il secondo un fatale che
# succede prima che il framework si avvii finisce in chiaro nella risposta HTTP.
# Chi sviluppa riaccende gli errori a video con DISPLAY_ERRORS=1.
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY resources/ /resources/
WORKDIR /resources
# php.ini coi default e xdebug spento gia' nell'immagine, l'entrypoint poi lo
# rifà con le env del container
RUN bash /resources/php-config.sh
RUN cat /resources/www.conf >> /usr/local/etc/php-fpm.d/www.conf
COPY /resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Dall'immagine ufficiale invece che con curl -k | php: niente TLS spento e
# niente installer scaricato a ogni build.
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Chi entra con `docker compose exec <srv> bash` si ritrova in fish. La guardia
# su PS1 lascia stare le shell non interattive (script, hook, comandi
# schedulati), IN_FISH evita il loop se da fish si rilancia bash.
RUN printf '\nif [ -n "$PS1" ] && [ -z "$IN_FISH" ] && [ -x /usr/bin/fish ]; then\n    export IN_FISH=1\n    exec /usr/bin/fish\nfi\n' >> /etc/bash.bashrc

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
