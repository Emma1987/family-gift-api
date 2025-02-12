# PHP with Apache
FROM php:8.2-apache AS symfony_php

# Install dependencies and PHP extensions
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        acl \
        file \
        gettext \
        git \
        unzip \
        libicu-dev \
        libzip-dev \
        zlib1g-dev \
        libxml2-dev \
        make \
        vim \
    ; \
    docker-php-ext-configure zip; \
    docker-php-ext-install -j$(nproc) \
        intl \
        zip \
        pdo_mysql \
        bcmath \
    ; \
    pecl install apcu; \
    pecl clear-cache; \
    docker-php-ext-enable apcu opcache; \
    a2enmod rewrite; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory
WORKDIR /var/app/html

# Copy custom Apache configuration
COPY ./docker/apache/conf/httpd.conf /etc/apache2/sites-available/000-default.conf

# Ensure the public/.htaccess file is copied
COPY ./public/.htaccess /var/app/html/public/.htaccess

# Copy application code
COPY . /var/app/html
RUN chown -R www-data:www-data /var/app/html && chmod -R 775 /var/app/html

# Copy custom entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Enable necessary Apache modules
RUN a2enmod rewrite

# Set the entrypoint to your script
ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]

# Set the default command to start Apache
CMD ["apache2-foreground"]

# Expose Apache's default ports
EXPOSE 80
EXPOSE 443
