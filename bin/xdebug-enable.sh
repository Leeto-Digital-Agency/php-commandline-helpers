#!/bin/bash

sudo echo "Asking Sudo Password" > /dev/null

getCurrentPhpVersion() {
    php -v | grep -oP '^PHP \K[0-9]+\.[0-9]+' | head -1
}

enableXdebug() {
    local CONFIG_FILE=$1
    echo "Enabling Xdebug in ${CONFIG_FILE}..."
    sudo sed -i 's/;\s*zend_extension\s*=\s*\(.*xdebug.so\)/zend_extension=\1/' "${CONFIG_FILE}"
}

PHP_VERSION="${1:-$(getCurrentPhpVersion)}"
FPM_CONFIG_FILE="/etc/php/${PHP_VERSION}/fpm/conf.d/20-xdebug.ini"
CLI_CONFIG_FILE="/etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini"

enableXdebug "${FPM_CONFIG_FILE}"
enableXdebug "${CLI_CONFIG_FILE}"

# Restart PHP-FPM to apply changes
echo "Restarting PHP-FPM to apply changes..."
sudo systemctl restart php"${PHP_VERSION}"-fpm

echo "Done."
