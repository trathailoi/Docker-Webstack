#!/bin/env bash
color_yellow_with_bg='\e[0;93;100m'
# Clear the color after that
color_clear='\033[0m \n\n'

if [ -z "${EXTRA_PACKAGES}" ]; then
    printf "${color_yellow_with_bg} No extra packages to install. ${color_clear}"
else
    printf "${color_yellow_with_bg} Installing extra packages... ${color_clear}"
    apk -U --no-cache add ${EXTRA_PACKAGES}
fi

if [ -z "${IS_WORDPRESS}" ]; then
    printf "${color_yellow_with_bg} Not a Wordpress site. No need to instal WP-CLI and packages. ${color_clear}"
else
    printf "${color_yellow_with_bg} Install PHP extensions - for WP-CLI ${color_clear}"
    apk -U --no-cache add \
        php7-phar \
        php7-json \
        php7-mysqli \
        php7-zip

    printf "${color_yellow_with_bg} Install WP-CLI ${color_clear}"
    # curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
    wget -P /tmp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
    chmod o+x /tmp/wp-cli.phar; chmod 755 /tmp/wp-cli.phar;
    mv /tmp/wp-cli.phar /usr/local/bin/wp;

    printf "${color_yellow_with_bg} Begin Download WP Core ${color_clear}"
    wp core download --skip-content --allow-root --path=/var/www/html

    printf "${color_yellow_with_bg} Correct permissions for UPLOADS folder ${color_clear}"
    mkdir -p /var/www/html/wp-content/uploads && mkdir -p /var/www/html/wp-content/uploads/cache
    chmod -R 777 /var/www/html/wp-content/uploads

    if [ -z "${HAS_COMPOSER}" ]; then
        printf "${color_yellow_with_bg} No Composer. ${color_clear}"
    else
        printf "${color_yellow_with_bg} Install PHP extensions - for Composer ${color_clear}"
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

        printf "${color_yellow_with_bg} Install Composer ${color_clear}"
        # php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/tmp/ --filename=composer; alias composer='php /tmp/composer';
        php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin/ --filename=composer;

        printf "${color_yellow_with_bg} Begin composer install ${color_clear}"
        # composer install --ignore-platform-reqs --working-dir=/var/www/html/wp-content/themes/$THEME_NAME/
        composer install --working-dir=/var/www/html/wp-content/themes/$THEME_NAME/
    fi

    # Generate wp-config.php file
    printf "${color_yellow_with_bg} Generate wp-config.php file ${color_clear}"
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
