FROM php:apache-stretch

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
    ghostscript

# Install the PHP extensions we need
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd
RUN yes | pecl install  mcrypt-1.0.2 && docker-php-ext-enable mcrypt && yes | pecl install imagick && docker-php-ext-enable imagick 

# Add the Omeka-S PHP code
# Latest Omeka version, check: https://omeka.org/s/download/
RUN wget --no-verbose "https://github.com/omeka/omeka-s/releases/download/v2.0.2/omeka-s-2.0.2.zip" -O /var/www/latest_omeka_s.zip
RUN unzip -q /var/www/latest_omeka_s.zip -d /var/www/ \
&&  rm /var/www/latest_omeka_s.zip \
&&  rm -rf /var/www/html/ \
&&  mv /var/www/omeka-s/ /var/www/html/

COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml
COPY ./.htaccess /var/www/html/.htaccess


# Create one volume for files, config, themes and modules
RUN mkdir -p /var/www/html/volume/config/ && mkdir -p /var/www/html/volume/files/ && mkdir -p /var/www/html/volume/modules/ && mkdir -p /var/www/html/volume/themes/

COPY ./database.ini /var/www/html/volume/config/
COPY ./local.config.php /var/www/html/volume/config/
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
CMD ["apache2-foreground"]
