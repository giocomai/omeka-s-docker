FROM php:8.2-apache-bookworm

# Omeka-S web publishing platform for digital heritage collections (https://omeka.org/s/)
# Previous maintainers: Oldrich Vykydal (o1da) - Klokan Technologies GmbH  / Eric Dodemont <eric.dodemont@skynet.be>
# MAINTAINER Giorgio Comai <g@giorgiocomai.eu>

RUN a2enmod rewrite

# Set default environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    APPLICATION_ENV=production

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Redirect Apache logs to stdout/stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

# Install system dependencies required by PHP extensions and Omeka-S
RUN apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install \
        # Utils needed later
        unzip \
        wget \
        ghostscript \
        poppler-utils \
        # PHP Extension Runtime/Build-time Libs (-dev packages needed for compilation)
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        # libjpeg-dev # Likely redundant with libjpeg62-turbo-dev
        libpng-dev \
        zlib1g-dev \
        libicu-dev \
        libsodium-dev \
        # For Imagick extension
        imagemagick \
        libmagickwand-dev \
    # Cleanup apt cache
    && apt-get clean

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install PHP extension installer tool
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install PHP extensions using the tool
# It will handle installing/removing temporary build dependencies (like build-essential)
RUN install-php-extensions \
    gd \
    iconv \
    pdo \
    pdo_mysql \
    mysqli \
    imagick \
    intl

# Add the Omeka-S PHP code
# Latest Omeka version, check: https://omeka.org/s/download/
RUN wget --no-verbose "https://github.com/omeka/omeka-s/releases/download/v4.1.1/omeka-s-4.1.1.zip" -O /var/www/latest_omeka_s.zip
RUN unzip -q /var/www/latest_omeka_s.zip -d /var/www/ \
&&  rm /var/www/latest_omeka_s.zip \
&&  rm -rf /var/www/html/ \
&&  mv /var/www/omeka-s/ /var/www/html/

COPY ./imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Create one volume for files, config, themes, modules and logs
RUN mkdir -p /var/www/html/volume/config/ && mkdir -p /var/www/html/volume/files/ && mkdir -p /var/www/html/volume/modules/ && mkdir -p /var/www/html/volume/themes/ && mkdir -p /var/www/html/volume/logs/


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
&& rm -Rf /var/www/html/logs/ \
&& ln -s /var/www/html/volume/logs/ /var/www/html/logs \
&& chown -R www-data:www-data /var/www/html/ \
&& chmod 600 /var/www/html/volume/config/database.ini \
&& chmod 600 /var/www/html/volume/config/local.config.php \
&& chmod 600 /var/www/html/.htaccess

VOLUME /var/www/html/volume/

# Overwrite the original Docker PHP entrypoint
COPY docker-php-entrypoint /usr/local/bin/

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
