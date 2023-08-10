#!/usr/bin/env bash

sed -i -e "s/REMOTE_HOST/${DOCKER_HOST_IP}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/REMOTE_PORT/${DOCKER_HOST_PORT}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/ENABLE_XDEBUG/${ENABLE_XDEBUG}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/ENABLE_MODE/${ENABLE_MODE}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/MAX_UPLOAD_SIZE/${MAX_UPLOAD_SIZE}/" /usr/local/etc/php/conf.d/php.ini
sed -i -e "s/POST_MAX_SIZE/${POST_MAX_SIZE}/" /usr/local/etc/php/conf.d/php.ini

if [ 0 == "${ENABLE_XDEBUG}" ]; then
    if [ -e /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ]; then
        rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    fi
fi

/usr/bin/supervisord
