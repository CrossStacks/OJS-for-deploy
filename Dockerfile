FROM php:8.2-apache

# System dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    unzip \
    git \
    curl \
    nodejs \
    npm \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    zip \
    intl \
    bcmath \
    ftp

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache rewrite
RUN a2enmod rewrite

# Set Apache root to OJS
ENV APACHE_DOCUMENT_ROOT=/var/www/html/ojs

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf

# Copy OJS
COPY ojs/ /var/www/html/ojs/

# Create config file from template
WORKDIR /var/www/html/ojs
RUN cp config.TEMPLATE.inc.php config.inc.php

# Install PKP lib dependencies
WORKDIR /var/www/html/ojs/lib/pkp
RUN composer install --no-dev --prefer-dist

# Install plugin dependencies
WORKDIR /var/www/html/ojs/plugins/paymethod/paypal
RUN composer install --no-dev --prefer-dist

WORKDIR /var/www/html/ojs/plugins/generic/citationStyleLanguage
RUN composer install --no-dev --prefer-dist

# Build frontend assets
WORKDIR /var/www/html/ojs
RUN npm install && npm run build

# Permissions (VERY IMPORTANT FOR OJS)
RUN chown -R www-data:www-data /var/www/html/ojs \
    && chmod -R 755 /var/www/html/ojs

WORKDIR /var/www/html/ojs
