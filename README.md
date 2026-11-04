# PHP-FPM 8.4

- Connettore MySQL (`pdo_mysql`)
- Xdebug 3, spento di default
- gd con JPEG, PNG, WebP e FreeType
- imagick (ImageMagick 7) + ghostscript, con i PDF leggibili
- ffmpeg per le conversioni video
- redis, igbinary, apcu, opcache, zip, intl, exif, bcmath
- composer

## Variabili d'ambiente

| Variabile          | Default | A cosa serve                                     |
|--------------------|---------|--------------------------------------------------|
| `MAX_UPLOAD_SIZE`  | `2M`    | `upload_max_filesize`                             |
| `POST_MAX_SIZE`    | `8M`    | `post_max_size`                                   |
| `DISPLAY_ERRORS`   | `0`     | errori a video: si accende solo in sviluppo       |
| `ENABLE_XDEBUG`    | `0`     | carica xdebug, in `mode=debug` a ogni richiesta   |
| `DOCKER_HOST_IP`   | `localhost` | host a cui xdebug si collega (`client_host`)  |
| `DOCKER_HOST_PORT` | `9003`  | porta su cui ascolta l'IDE (`client_port`)        |

Il `php.ini` viene rigenerato dal template a ogni avvio, quindi per cambiare
questi valori basta modificare l'ambiente e riavviare il container: non serve
ricrearlo. Vale anche per `ENABLE_XDEBUG`, che si spegne e si riaccende.
Lo stesso php.ini, coi default, e' gia' nell'immagine: anche i `RUN` delle
immagini figlie e `docker compose run` lo trovano a posto, con xdebug spento.

Il php.ini di base e' quello **di produzione**: gli errori restano fuori dalla
risposta HTTP finche' non si passa `DISPLAY_ERRORS=1`.

## Note

- I log di php-fpm e di supervisord escono su `docker logs`.
- `docker compose exec <servizio> bash` apre una shell fish.
- Base Debian 13 (trixie). Composer viene dall'immagine `composer:2`.
- L'immagine gira come root: supervisord lancia i worker con `user=www-data`.
- `/app/var` appartiene a `www-data`; l'immagine non dichiara `VOLUME`, i mount
  li decide il compose.
- La porta di php-fpm e' la 9000.
