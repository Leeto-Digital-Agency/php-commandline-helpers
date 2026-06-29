#!/bin/bash
#
# switch-php [version] — make <version> the active `php` (e.g. switch-php 8.3).
# Version resolution: argument → ./.php-version → interactive prompt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

version="$(ph_resolve_version "${1:-}" --list)" || exit 1

if [ "$(ph_os)" = "macos" ]; then
    # Resolve to an INSTALLED formula first; never unlink until we know the
    # target exists, otherwise a typo would leave the user with no linked php.
    formula="$(ph_resolve_formula "$version")" || formula=""
    if [ -z "$formula" ]; then
        echo "PHP ${version} is not installed via Homebrew." >&2
        echo "Install it first:  install-php ${version}" >&2
        echo "Installed versions:" >&2
        ph_list_versions >&2
        exit 1
    fi

    previous="$(ph_linked_formula || true)"

    while read -r installed; do
        [ -n "$installed" ] || continue
        brew unlink "$installed" >/dev/null 2>&1 || true
    done < <(ph_installed_php_formulae)

    echo "Linking ${formula}..."
    if ! brew link --overwrite --force "$formula"; then
        echo "Failed to link ${formula}." >&2
        if [ -n "$previous" ] && [ "$previous" != "$formula" ]; then
            echo "Rolling back to ${previous}..." >&2
            brew link --overwrite --force "$previous" >/dev/null 2>&1 || true
        fi
        exit 1
    fi
    ph_restart_fpm "$version"
else
    sudo -v
    sudo update-alternatives --set php "/usr/bin/php${version}"
fi

printf '\033[1;42mPHP version switched to %s\033[0m\n' "$version"
php -v | head -1 || true
