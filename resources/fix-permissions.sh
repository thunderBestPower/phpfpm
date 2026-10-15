#!/usr/bin/env bash
# Rende di appuser le cartelle in cui l'app scrive. Gira come root tramite sudo
# dall'entrypoint: i file già presenti possono appartenere a un altro uid (per esempio
# creati da una versione precedente dell'immagine) e appuser non potrebbe scriverci,
# quindi supervisord non partirebbe o l'app non leggerebbe i propri file.
#
# Si ferma a /app: sudo è concesso ad appuser solo per questo script.
set -u

# supervisord scrive log e pid qui: se la cartella non esiste non parte
mkdir -p /app/var/log

for dir in "$@"; do
    real=$(realpath -e "$dir" 2>/dev/null) || continue
    case "$real" in
        /app/*) ;;
        *)
            echo "fix-permissions: $dir è fuori da /app, la salto" >&2
            continue
            ;;
    esac

    # -xdev: le share di rete montate dentro (es. cifs) non si attraversano;
    # tocco solo i file con proprietario diverso, così all'avvio è veloce
    find "$real" -xdev \( ! -user appuser -o ! -group appgroup \) \
        -exec chown -h appuser:appgroup {} + 2>/dev/null || true
done
