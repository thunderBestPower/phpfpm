# PHP-FPM 8.4

Immagine PHP-FPM basata su `php:8.4-fpm`.

## Estensioni

- Postgres (`pdo_pgsql`), MSSQL/Sybase (`pdo_dblib` via FreeTDS)
- **IBM DB2** (`ibm_db2` 2.3.1 + IBM Data Server Driver 11.5.4)
- Xdebug, Redis, igbinary, APCu, OPcache
- gd, zip, intl, ftp

## Prerequisiti per il build

Il driver IBM non è scaricabile automaticamente: serve il file
`resources/v11.5.4_linuxx64_dsdriver.tar.gz`, ottenibile dal sito IBM
(Data Server Driver Package, Linux x86-64).

```bash
docker build -t phpfpm .
```

## Variabili d'ambiente

| Variabile | Default | Descrizione |
|---|---|---|
| `MAX_UPLOAD_SIZE` | `2M` | `upload_max_filesize` |
| `POST_MAX_SIZE` | `8M` | `post_max_size` |
| `ENABLE_XDEBUG` | `no` | `xdebug.start_with_request` |
| `ENABLE_MODE` | `debug` | `xdebug.mode` (`off` per disattivarlo) |
| `DOCKER_HOST_IP` | — | `xdebug.client_host` |
| `DOCKER_HOST_PORT` | — | `xdebug.client_port` |

I valori vengono applicati all'avvio da `resources/entrypoint.sh`, che
sostituisce i placeholder in `conf.d/php.ini` e lancia supervisord.

## Permessi

L'immagine gira come utente `appuser`. UID e GID sono configurabili in
fase di build per allinearli a quelli dell'host ed evitare problemi di
permessi sul volume `/app`:

```yaml
build:
  args:
    UID: 1000
    GID: 1000
```

## Note

L'estensione `ibm_db2` richiede `LD_LIBRARY_PATH=/opt/ibm/dsdriver/lib`,
già impostata nel Dockerfile: se la sovrascrivi a runtime l'estensione
non si carica più.
