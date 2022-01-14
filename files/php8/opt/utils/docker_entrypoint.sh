#!/bin/env bash

if [ -z "${EXTRA_PACKAGES}" ]; then
    echo "\e[1;93;100m No extra packages to install. \e[0m"
else
    echo "\e[1;93;100m Installing extra packages... \e[0m"
    apk -U --no-cache add ${EXTRA_PACKAGES}
fi

if [ -z "${IS_WORDPRESS}" ]; then
    echo "\e[1;93;100m Not a Wordpress site. No need to instal WP-CLI and packages. \e[0m"
else
    echo "\e[1;93;100m Install PHP extensions - for WP-CLI \e[0m"
    apk -U --no-cache add \
        php8-phar \
        php8-json \
        php8-mysqli \
        php8-zip

    echo "\e[1;93;100m Install WP-CLI \e[0m"
    # curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
    wget -P /tmp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
    chmod o+x /tmp/wp-cli.phar; chmod 755 /tmp/wp-cli.phar;
    mv /tmp/wp-cli.phar /usr/local/bin/wp;

    echo "\e[1;93;100m Begin Download WP Core \e[0m"
    wp core download --skip-content --allow-root --path=/var/www/html

    echo "\e[1;93;100m Correct permissions for UPLOADS folder \e[0m"
    mkdir -p /var/www/html/wp-content/uploads && mkdir -p /var/www/html/wp-content/uploads/cache
    chmod -R 777 /var/www/html/wp-content/uploads

    if [ -z "${HAS_COMPOSER}" ]; then
        echo "\e[1;93;100m No Composer. \e[0m"
    else
        echo "\e[1;93;100m Install PHP extensions - for Composer \e[0m"
        apk -U --no-cache add \
            php8-bcmath \
            php8-bz2 \
            php8-dom \
            php8-xmlrpc \
            php8-common \
            php8-curl \
            php8-ctype \
            php8-soap \
            php8-gd \
            php8-iconv \
            php8-mbstring \
            php8-mysqlnd \
            php8-openssl \
            php8-pdo_mysql \
            php8-session \
            php8-xml \
            php8-simplexml \
            php8-tokenizer \
            php8-xmlwriter

        echo "\e[1;93;100m Install Composer \e[0m"
        # php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/tmp/ --filename=composer; alias composer='php /tmp/composer';
        php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin/ --filename=composer;

        echo "\e[1;93;100m Begin composer install \e[0m"
        # composer install --ignore-platform-reqs --working-dir=/var/www/html/wp-content/themes/$THEME_NAME/
        composer install --working-dir=/var/www/html/wp-content/themes/$THEME_NAME/
    fi

    # Generate wp-config.php file
    echo "\e[1;93;100m Generate wp-config.php file \e[0m"
    awk '
            /put your unique phrase here/ {
                    cmd = "head -c1m /dev/urandom | sha1sum | cut -d\\  -f1"
                    cmd | getline str
                    close(cmd)
                    gsub("put your unique phrase here", str)
            }
            { print }
    ' "/tmp/wp-config-docker.php" > /var/www/html/wp-config.php
fi

# use "set" for Wordpress to recognize environment variables
echo "$VIRTUAL_HOST"
set -eux;
exec "$@"
