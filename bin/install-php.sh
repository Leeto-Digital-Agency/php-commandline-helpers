#!/bin/bash

sudo echo "Asking Sudo Password" > /dev/null

if [ -z "$1" ]; then

    if [ -f .php-version ]; then
        version=$(cat .php-version)
    else
        echo "Please provide the PHP version you want to install"
        echo "Available PHP versions:"
        ls -A1 /etc/php
        read -p "PHP version: " version
    fi
else
    version=$1
fi


sudo apt-get install -y php"$version"-fpm php"$version"-cli php"$version"-mysql php"$version"-curl php"$version"-gd php"$version"-intl php"$version"-mbstring php"$version"-xml php"$version"-zip php"$version"-bcmath php"$version"-json php"$version"-common php"$version"-dev php"$version"-soap php"$version"-sqlite3 php"$version"-sqlite3 php"$version"-xdebug

echo -e "\e[1;42mPHP version $version installed\e[0m"
