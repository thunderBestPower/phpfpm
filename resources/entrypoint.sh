#!/usr/bin/env bash

sed -i -e "s/REMOTE_PORT/${DOCKER_HOST_PORT}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/REMOTE_HOST/${DOCKER_HOST_IP}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/ENABLE_MODE/${ENABLE_MODE}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/ENABLE_XDEBUG/${ENABLE_XDEBUG}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/MAX_UPLOAD_SIZE/${MAX_UPLOAD_SIZE}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/POST_MAX_SIZE/${POST_MAX_SIZE}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/MEMORY_LIMIT/${MEMORY_LIMIT}/" /usr/local/etc/php/conf.d/php.ini

# Disattiva Xdebug se non richiesto (ENABLE_XDEBUG=no/0 oppure ENABLE_MODE=off)
case "${ENABLE_XDEBUG,,}:${ENABLE_MODE,,}" in
    no:* | 0:* | *:off)
        rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
        ;;
esac

# crea /app/var/log e rende di appuser i file scritti con un altro uid
# (senza virgolette: FIX_PERMISSIONS_DIRS è un elenco separato da spazi)
sudo /usr/local/bin/fix-permissions ${FIX_PERMISSIONS_DIRS}

# config dedicata: quella di sistema usa /var/run e /var/log, non scrivibili da appuser
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
