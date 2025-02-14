#!/bin/bash

sudo echo "Asking Sudo Password" > /dev/null

if [ -z "$1" ]; then

    if [ -f .php-version ]; then
        version=$(cat .php-version)
    else
        echo "Please provide the PHP version you want to use"
        echo "Available PHP versions:"
        ls -A1 /etc/php
        read -p "PHP version: " version
    fi
else
    version=$1
fi

sudo update-alternatives --set php /usr/bin/php"$version"
echo -e "\e[1;42mPHP version switched to $version\e[0m"
