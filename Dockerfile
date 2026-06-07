FROM php:8.5-apache

ARG DEV=0
ENV DEBUG=$DEV

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    wget \
    libzip-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libwebp-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libbz2-dev

# Make changes to the php.ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' "$PHP_INI_DIR/php.ini" && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' "$PHP_INI_DIR/php.ini" && \
    sed -i 's/post_max_size = 8M/post_max_size = 256M/' "$PHP_INI_DIR/php.ini"

# Install necessary php extensions
RUN a2enmod rewrite && \
    docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install zip && \
    docker-php-ext-install bz2 && \
    docker-php-ext-install bcmath && \
    if [ $DEV -ge 1 ]; then \
      pecl install xdebug && docker-php-ext-enable xdebug \
      && echo "xdebug.mode=debug" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
      && echo "xdebug.client_host=172.17.0.1" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
      && echo "xdebug.client_port=9003" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
      && echo "xdebug.start_with_request=yes" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
      && echo "xdebug.log=/tmp/xdebug.log" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini; \
    fi

# Install latest composer 2.x
RUN wget -q -O /usr/local/bin/composer https://getcomposer.org/download/latest-2.x/composer.phar && \
    chmod 755 /usr/local/bin/composer

COPY . /var/www/drupal

VOLUME /var/www/drupal/web/sites/default/files
VOLUME /var/www/drupal/private/files

RUN rm -rf /var/www/html && ln -s /var/www/drupal/web /var/www/html

WORKDIR /var/www/drupal

# Install composer dependencies
RUN composer install

RUN if [ $DEV -ge 1 ]; then \
      apt-get install -y iputils-ping; \
    fi

ENV PATH=/var/www/drupal/vendor/bin:$PATH

WORKDIR /var/www/drupal/web
