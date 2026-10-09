FROM php:8.2-apache
RUN apt-get update && apt-get install -y libpng-dev libonig-dev libxml2-dev zip unzip git curl && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
