FROM php:7.3-apache

# add mcript and gd extension for php
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libcurl4-gnutls-dev \
        libmcrypt-dev \
        locales \
        graphicsmagick \
	#mysql-client for php 7.0
	#mysql-client \
	#mariadb-client for php 7.3
	mariadb-client \
        unzip \
        wget \
	cmake \
    && rm -rf /var/lib/apt/lists/*

# Reinstall libzip
RUN wget https://libzip.org/download/libzip-1.7.3.tar.gz \
    && tar -zxvf libzip-1.7.3.tar.gz \
    && cd libzip-1.7.3 \
    && mkdir build && cd build && cmake .. && make && make install

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) pdo_mysql exif zip gd opcache

# set recommended PHP.ini settings
# see http://docs.filerun.com/php_configuration
COPY filerun-optimization.ini /usr/local/etc/php/conf.d/

# Install Ioncube
RUN curl -O http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
 && tar xvfz ioncube_loaders_lin_x86-64.tar.gz \
 && PHP_EXT_DIR=$(php-config --extension-dir) \
 && cp "ioncube/ioncube_loader_lin_7.3.so" $PHP_EXT_DIR \
 && echo "zend_extension=ioncube_loader_lin_7.3.so" >> /usr/local/etc/php/conf.d/00_ioncube_loader_lin_7.3.ini \
 && rm -rf ioncube ioncube_loaders_lin_x86-64.tar.gz

#RUN /usr/sbin/a2enmod rewrite

# Install filerun
RUN curl -o /filerun.zip -L https://www.filerun.com/download-latest \
 && mkdir /user-files \
 && chown www-data:www-data /user-files

COPY db.sql /filerun.setup.sql
COPY autoconfig.php /

EXPOSE 80 6800
VOLUME ["/var/www/html", "/user-files"]

COPY ./entrypoint.sh /
COPY ./wait-for-it.sh /
COPY ./import-db.sh /
RUN chmod +x /entrypoint.sh /wait-for-it.sh /import-db.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
