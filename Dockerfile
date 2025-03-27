FROM php:8.2-apache-bookworm

# Omeka-S web publishing platform for digital heritage collections (https://omeka.org/s/)
# Previous maintainers: Oldrich Vykydal (o1da) - Klokan Technologies GmbH  / Eric Dodemont <eric.dodemont@skynet.be>
# MAINTAINER Giorgio Comai <g@giorgiocomai.eu>

RUN a2enmod rewrite

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq -y upgrade
RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick \
    libmagickwand-dev \
    wget \
    ghostscript \
    poppler-utils \
    libsodium-dev \
    libicu-dev

# Install the PHP extensions we need
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/
RUN docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd
RUN yes | pecl install imagick && docker-php-ext-enable imagick 

# Support for more languages, e.g. for date formatting and month names
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl

# Add the Omeka-S PHP code
# Latest Omeka version, check: https://omeka.org/s/download/
RUN wget --no-verbose "https://github.com/omeka/omeka-s/releases/download/v4.1.1/omeka-s-4.1.1.zip" -O /var/www/latest_omeka_s.zip
RUN unzip -q /var/www/latest_omeka_s.zip -d /var/www/ \
&&  rm /var/www/latest_omeka_s.zip \
&&  rm -rf /var/www/html/ \
&&  mv /var/www/omeka-s/ /var/www/html/

COPY ./imagemagick-policy.xml /etc/ImageMagick-6/policy.xml
COPY ./.htaccess /var/www/html/.htaccess


# Create one volume for files, config, themes and modules
RUN mkdir -p /var/www/html/volume/config/ && mkdir -p /var/www/html/volume/files/ && mkdir -p /var/www/html/volume/modules/ && mkdir -p /var/www/html/volume/themes/

COPY ./database.ini /var/www/html/volume/config/
COPY ./local.config.php /var/www/html/volume/config/

# Create script to update database.ini with environment variables
RUN echo '#!/bin/sh\n\
if [ ! -z "$DB_USER" ]; then sed -i "s/^user\\s*=.*/user     = \"$DB_USER\"/" /var/www/html/volume/config/database.ini; fi\n\
if [ ! -z "$DB_PASSWORD" ]; then sed -i "s/^password\\s*=.*/password = \"$DB_PASSWORD\"/" /var/www/html/volume/config/database.ini; fi\n\
if [ ! -z "$DB_NAME" ]; then sed -i "s/^dbname\\s*=.*/dbname   = \"$DB_NAME\"/" /var/www/html/volume/config/database.ini; fi\n\
if [ ! -z "$DB_HOST" ]; then sed -i "s/^host\\s*=.*/host     = \"$DB_HOST\"/" /var/www/html/volume/config/database.ini; fi\n\
if [ ! -z "$DB_PORT" ]; then sed -i "s/^;port\\s*=.*/port     = \"$DB_PORT\"/" /var/www/html/volume/config/database.ini; fi\n\
if [ ! -z "$DB_SOCKET" ]; then sed -i "s/^;unix_socket\\s*=.*/unix_socket = \"$DB_SOCKET\"/" /var/www/html/volume/config/database.ini; fi\n\
if [ ! -z "$DB_LOG_PATH" ]; then sed -i "s/^;log_path\\s*=.*/log_path = \"$DB_LOG_PATH\"/" /var/www/html/volume/config/database.ini; fi\n\
exec "$@"' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

RUN rm /var/www/html/config/database.ini \
&& ln -s /var/www/html/volume/config/database.ini /var/www/html/config/database.ini \
&& rm /var/www/html/config/local.config.php \
&& ln -s /var/www/html/volume/config/local.config.php /var/www/html/config/local.config.php \
&& rm -Rf /var/www/html/files/ \
&& ln -s /var/www/html/volume/files/ /var/www/html/files \
&& rm -Rf /var/www/html/modules/ \
&& ln -s /var/www/html/volume/modules/ /var/www/html/modules \
&& rm -Rf /var/www/html/themes/ \
&& ln -s /var/www/html/volume/themes/ /var/www/html/themes \
&& chown -R www-data:www-data /var/www/html/ \
&& chmod 600 /var/www/html/volume/config/database.ini \
&& chmod 600 /var/www/html/volume/config/local.config.php \
&& chmod 600 /var/www/html/.htaccess

VOLUME /var/www/html/volume/
\
CMD echo "ServerName localhost" >> /etc/apache2/apache2.conf
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
