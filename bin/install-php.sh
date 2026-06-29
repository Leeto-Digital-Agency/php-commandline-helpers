#!/bin/bash
#
# install-php [version] — install a PHP version (e.g. install-php 8.3).
# macOS: Homebrew core formula + Xdebug via pecl. Linux: apt packages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

version="$(ph_resolve_version "${1:-}")" || exit 1

if [ "$(ph_os)" = "macos" ]; then
    # php@<latest> is a Homebrew alias of `php`, so the versioned name is safe.
    formula="$(ph_brew_formula "$version")"

    echo "Installing ${formula} from Homebrew core..."
    if ! brew install "$formula"; then
        echo "Failed to install ${formula}." >&2
        echo "Only versions in Homebrew core are supported. Check 'brew search php@' for what's available." >&2
        exit 1
    fi

    # Homebrew core PHP ships without Xdebug; install it via pecl so the
    # xdebug-enable / xdebug-disable helpers have something to toggle.
    pecl_bin="$(ph_brew_prefix)/opt/${formula}/bin/pecl"
    if [ -x "$pecl_bin" ]; then
        echo "Installing Xdebug via pecl..."
        "$pecl_bin" install xdebug || echo "Xdebug install skipped/failed (it may already be installed)."
        # pecl appends a zend_extension line to php.ini; remove it so Xdebug
        # loading is owned by conf.d (xdebug-enable) and php.ini stays clean.
        ph_strip_xdebug_load_from_ini "$version"
    fi
else
    sudo -v
    # php<v>-json is a separate package only on PHP 7.x; JSON is in core for >=8.0.
    extra=()
    case "$version" in 7.*) extra+=("php${version}-json") ;; esac
    sudo apt-get install -y \
        "php${version}-fpm" "php${version}-cli" "php${version}-mysql" \
        "php${version}-curl" "php${version}-gd" "php${version}-intl" \
        "php${version}-mbstring" "php${version}-xml" "php${version}-zip" \
        "php${version}-bcmath" "php${version}-common" "php${version}-dev" \
        "php${version}-soap" "php${version}-sqlite3" "php${version}-xdebug" \
        ${extra[@]+"${extra[@]}"}
fi

printf '\033[1;42mPHP version %s installed\033[0m\n' "$version"
