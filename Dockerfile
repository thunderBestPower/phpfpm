# docker/php/Dockerfile
FROM php:8.2-fpm

RUN apt-get update
RUN docker-php-ext-install pdo pdo_mysql mysqli


EXPOSE 9000
CMD ["bash"]