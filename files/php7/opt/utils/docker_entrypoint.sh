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
        php7-phar \
        php7-json \
        php7-mysqli \
        php7-zip

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
            php7-bcmath \
            php7-bz2 \
            php7-dom \
            php7-xmlrpc \
            php7-common \
            php7-curl \
            php7-ctype \
            php7-soap \
            php7-gd \
            php7-iconv \
            php7-mbstring \
            php7-mysqlnd \
            php7-openssl \
            php7-pdo_mysql \
            php7-session \
            php7-xml \
            php7-simplexml \
            php7-tokenizer \
            php7-xmlwriter

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
