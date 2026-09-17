# PHP-FPM 8.2

- Include connect Postgres
- Xdebug
- PDO (per collegarsi al database di Microsoft)
- Estensioni: opcache, pdo_pgsql, pdo_dblib, sqlsrv, pdo_sqlsrv, gd (JPEG, PNG, WebP), exif, zip, intl, redis, igbinary, apcu
- Composer 2, supervisor, fish, pdftk

Ho preso spunto sia da questo https://stackoverflow.com/questions/51933001/install-configure-sql-server-pdo-driver-for-php-docker-image che da https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16&tabs=ubuntu18-install%2Cubuntu17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline

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

```yaml
services:
  php:
    environment:
      MEMORY_LIMIT: 512M
      ENABLE_XDEBUG: trigger
```

## Note

- Il container gira come `appuser` (uid `1999`, non root), anche php-fpm e supervisord.
- supervisord usa solo `resources/supervisord.conf` (`-c`): la config di sistema scrive in
  `/var/run` e `/var/log`, non scrivibili da `appuser`, e il container non partirebbe.
- Log e pid di supervisord/php-fpm sono in `/app/var/log`, creata dall'entrypoint se manca.
- Driver SQL Server dal repo Microsoft per Debian 13; `sqlsrv`/`pdo_sqlsrv` fissati a `5.12.0`
  perché dalla 5.13 serve PHP >= 8.3.
