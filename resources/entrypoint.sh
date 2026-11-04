#!/usr/bin/env bash
set -e

# php.ini e xdebug dalle env del container, vedi php-config.sh
bash /resources/php-config.sh

# exec: supervisord deve restare PID 1, se no bash si tiene il segnale e ogni
# `docker stop` aspetta i 10 secondi di timeout prima del SIGKILL.
exec /usr/bin/supervisord
