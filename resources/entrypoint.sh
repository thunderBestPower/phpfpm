#!/usr/bin/env bash
set -e

# Il php.ini viene rigenerato dal template a ogni avvio: i sed consumano i
# placeholder, quindi sostituendo in place il file si sarebbe potuto configurare
# una volta sola - dal secondo start in poi cambiare le env e fare `restart` non
# aveva piu' alcun effetto.
cp /resources/php.ini "$PHP_INI_DIR/conf.d/php.ini"

sed -i -e "s/REMOTE_HOST/${DOCKER_HOST_IP}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/REMOTE_PORT/${DOCKER_HOST_PORT}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/DISPLAY_ERRORS/${DISPLAY_ERRORS}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/ENABLE_XDEBUG/${ENABLE_XDEBUG}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/MAX_UPLOAD_SIZE/${MAX_UPLOAD_SIZE}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/POST_MAX_SIZE/${POST_MAX_SIZE}/" "$PHP_INI_DIR/conf.d/php.ini"

# Stesso discorso: l'estensione va rimessa, non solo tolta, altrimenti dopo un
# avvio con ENABLE_XDEBUG=0 non si riaccende piu' senza ricreare il container.
if [ "0" == "${ENABLE_XDEBUG}" ]; then
    rm -f "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
else
    docker-php-ext-enable xdebug
fi

# exec: supervisord deve restare PID 1, se no bash si tiene il segnale e ogni
# `docker stop` aspetta i 10 secondi di timeout prima del SIGKILL.
exec /usr/bin/supervisord
