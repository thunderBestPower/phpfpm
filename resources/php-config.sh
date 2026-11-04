#!/usr/bin/env bash
set -e

# Lo chiamo sia dal Dockerfile, coi default, sia dall'entrypoint a ogni avvio.
# Se lo facesse solo l'entrypoint, tutto quello che gira senza passare di li' -
# i RUN delle immagini figlie, `docker compose run` - si troverebbe il php.ini
# coi placeholder grezzi e xdebug acceso che prova a collegarsi a ogni comando.

# Il php.ini viene rigenerato dal template ogni volta: i sed consumano i
# placeholder, quindi sostituendo in place il file si sarebbe potuto configurare
# una volta sola - dal secondo start in poi cambiare le env e fare `restart` non
# aveva piu' alcun effetto.
cp /resources/php.ini "$PHP_INI_DIR/conf.d/php.ini"

# Default anche qui: con la porta vuota xdebug si lamenta a ogni avvio di php.
# 9003 e' quella di default di Xdebug 3, la 9000 era della 2.
sed -i -e "s/REMOTE_HOST/${DOCKER_HOST_IP:-localhost}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/REMOTE_PORT/${DOCKER_HOST_PORT:-9003}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/DISPLAY_ERRORS/${DISPLAY_ERRORS}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/MAX_UPLOAD_SIZE/${MAX_UPLOAD_SIZE}/" "$PHP_INI_DIR/conf.d/php.ini"
sed -i -e "s/POST_MAX_SIZE/${POST_MAX_SIZE}/" "$PHP_INI_DIR/conf.d/php.ini"

# Stesso discorso: l'estensione va rimessa, non solo tolta, altrimenti dopo un
# avvio con ENABLE_XDEBUG=0 non si riaccende piu' senza ricreare il container.
if [ "0" == "${ENABLE_XDEBUG}" ]; then
    rm -f "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
else
    docker-php-ext-enable xdebug
fi
