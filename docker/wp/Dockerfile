FROM wordpress:php8.4-fpm

# Add system dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    curl \
    nano \
    git \
    mariadb-client \
    iputils-ping \
    less \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql opcache

# Install Redis extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create xdebug log directory
RUN mkdir -p /var/log/xdebug \
    && chown www-data:www-data /var/log/xdebug

# Create php log directory
RUN mkdir -p /var/log/php \
    && chown www-data:www-data /var/log/php

# Configure php.ini settings
RUN { \
    echo 'memory_limit = 1024M'; \
    echo 'max_execution_time = 300'; \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'date.timezone = "UTC"'; \
} > /usr/local/etc/php/conf.d/wordpress.ini

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD php -r 'if(!file_exists("/var/www/html/wp-config.php")) { exit(1); } else { exit(0); }'

WORKDIR /var/www/html
