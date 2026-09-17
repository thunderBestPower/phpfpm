# PHP-FPM 8.4

- Include connect Postgres
- Xdebug
- Estensioni: opcache, pdo_pgsql, gd (JPEG, PNG, WebP), exif, zip, intl, ftp, redis, igbinary, apcu
- Composer 2, supervisor, fish

## Variabili d'ambiente

| Variabile         | Default | Descrizione                                                               |
|-------------------|---------|---------------------------------------------------------------------------|
| `MEMORY_LIMIT`    | `128M`  | `memory_limit` di PHP (`-1` = nessun limite)                              |
| `PM_MAX_CHILDREN` | `5`     | `pm.max_children` di php-fpm: richieste servite in parallelo             |
| `MAX_UPLOAD_SIZE` | `2M`    | `upload_max_filesize`                                                     |
| `POST_MAX_SIZE`   | `8M`    | `post_max_size`                                                           |
| `ENABLE_XDEBUG`   | `no`    | `xdebug.start_with_request`: `yes`, `trigger` oppure `no`/`0` (rimuove Xdebug) |
| `ENABLE_MODE`     | `debug` | `xdebug.mode`: con `off` Xdebug viene rimosso                             |
| `DOCKER_HOST_IP`  |         | `xdebug.client_host`                                                      |
| `DOCKER_HOST_PORT`|         | `xdebug.client_port`                                                      |

I valori vengono scritti nel `php.ini` dall'entrypoint al **primo avvio** del container:
dopo averli cambiati serve ricrearlo (`docker compose up -d`), non basta `docker restart`.

## Build args

`UID` e `GID` (default `1000`): devono corrispondere al proprio utente host, così i file
creati in `/app` hanno i permessi giusti.

```yaml
services:
  php:
    build:
      args:
        UID: 1000
        GID: 1000
    environment:
      MEMORY_LIMIT: 512M
      ENABLE_XDEBUG: trigger
```

## Note

- Il container gira come `appuser` (non root), anche php-fpm e supervisord.
- supervisord usa solo `resources/supervisord.conf` (`-c`): la config di sistema scrive in
  `/var/run` e `/var/log`, non scrivibili da `appuser`, e il container non partirebbe.
- Log e pid di supervisord/php-fpm sono in `/app/var/log`, creata dall'entrypoint se manca.
