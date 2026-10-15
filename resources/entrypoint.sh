#!/usr/bin/env bash

# I valori di php.ini (upload, xdebug) li legge PHP dalle variabili d'ambiente, vedi resources/php.ini

if [ 0 == "${ENABLE_XDEBUG}" ]; then
    if [ -e /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ]; then
        rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    fi
fi

/usr/bin/supervisord
