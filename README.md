# PHP Helpers
This repository contains a set of bash scripts that help with managing PHP versions when installed with PHP-FPM.
When installing you will have a set of helpers `switch-php`, `xdebug-enable`, `xdebug-disable` and `install-php`.


## Installation

To install the package, run the following command:

```bash
bash install.sh
```

You will also need to add xdebug to your php.ini file. You can do this by adding the following lines to your /etc/php/VERSION/fpm/php.ini file:

```ini
[Xdebug]
xdebug.mode=debug
xdebug.start_with_request=trigger
```

## Usage

### Switch PHP

To switch between PHP versions, run the following command:

```bash
switch-php 7.4
```

If the version is missing then script will check if there is a .php-version file in the current directory and use that version.
If a file does not exist, the script will ask you to enter the version you want to switch to.

### Enable Xdebug

To enable Xdebug, run the following command:

```bash
xdebug-enable
```

### Disable Xdebug

To disable Xdebug, run the following command:

```bash
xdebug-disable
```

### Install PHP

To install a new PHP version, run the following command:

```bash
install-php 7.4
```

