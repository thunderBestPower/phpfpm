# PHP-FPM 7.4

- Connettore MySQL (`pdo_mysql`)
- Xdebug 2.9.0, spento di default
- gd con JPEG, PNG, WebP e FreeType
- imagick + ghostscript, con la policy di ImageMagick che riapre i PDF
- ffmpeg per le conversioni video
- redis, igbinary, apcu, opcache, zip, intl, xmlrpc
- composer

## Variabili d'ambiente

| Variabile          | Default | A cosa serve                                     |
|--------------------|---------|--------------------------------------------------|
| `MAX_UPLOAD_SIZE`  | `2M`    | `upload_max_filesize`                             |
| `POST_MAX_SIZE`    | `8M`    | `post_max_size`                                   |
| `DISPLAY_ERRORS`   | `0`     | errori a video: si accende solo in sviluppo       |
| `ENABLE_XDEBUG`    | `0`     | carica xdebug e accende `remote_autostart`        |
| `DOCKER_HOST_IP`   | -       | host a cui xdebug si collega                      |
| `DOCKER_HOST_PORT` | -       | porta su cui ascolta l'IDE                        |

Il `php.ini` viene rigenerato dal template a ogni avvio, quindi per cambiare
questi valori basta modificare l'ambiente e riavviare il container: non serve
ricrearlo. Vale anche per `ENABLE_XDEBUG`, che si spegne e si riaccende.

Il php.ini di base e' quello **di produzione**: gli errori restano fuori dalla
risposta HTTP finche' non si passa `DISPLAY_ERRORS=1`.

## Note

- I log di php-fpm e di supervisord escono su `docker logs`.
- `docker compose exec <servizio> bash` apre una shell fish.
- Bullseye e' fuori supporto: i pacchetti arrivano da `archive.debian.org`.
- `/app/var` appartiene a `www-data`; l'immagine non dichiara `VOLUME`, i mount
  li decide il compose.
- La porta di php-fpm e' la 9000.
