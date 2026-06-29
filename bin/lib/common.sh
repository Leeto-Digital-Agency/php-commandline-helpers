#!/bin/bash
#
# common.sh — shared helpers for the php-commandline-helpers scripts.
#
# Sourced by switch-php / install-php / xdebug-enable / xdebug-disable. Keeps all
# the macOS (Homebrew) vs Linux (apt / update-alternatives) branching, version
# resolution, and the xdebug toggle in one place so the commands stay thin.

# ph_os — echo "macos" or "linux".
ph_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        *)      echo "linux" ;;
    esac
}

# ph_brew_prefix — Homebrew install prefix (e.g. /opt/homebrew or /usr/local).
ph_brew_prefix() {
    brew --prefix 2>/dev/null
}

# ph_brew_formula <version> — versioned Homebrew formula name (e.g. php@8.3).
# Homebrew ships php@<latest> as an alias of `php`, so this is safe for install.
ph_brew_formula() {
    echo "php@$1"
}

# ph_installed_php_formulae — installed php* formulae, one per line (macOS).
ph_installed_php_formulae() {
    brew list --formula 2>/dev/null | grep -E '^php(@[0-9.]+)?$'
}

# ph_brew_latest_version — MAJOR.MINOR of the unversioned `php` formula (latest).
ph_brew_latest_version() {
    brew list --versions php 2>/dev/null | awk '{print $2}' | grep -oE '^[0-9]+\.[0-9]+' | head -1
}

# ph_resolve_formula <version> — echo the INSTALLED Homebrew formula for a PHP
# version, or nothing + return 1 if it is not installed. Prefers php@<version>;
# falls back to the unversioned `php` when that is the requested (latest) version.
# Never fabricates a name, so callers can guard before destructive actions.
ph_resolve_formula() {
    local version="$1"
    if ph_installed_php_formulae | grep -qx "php@${version}"; then
        echo "php@${version}"
        return 0
    fi
    if ph_installed_php_formulae | grep -qx "php" && [ "$(ph_brew_latest_version)" = "$version" ]; then
        echo "php"
        return 0
    fi
    return 1
}

# ph_linked_formula — the php formula currently linked into the brew prefix
# (e.g. php@8.3 or php), derived from the `php` symlink. Empty + return 1 if none.
ph_linked_formula() {
    local link
    link="$(readlink "$(ph_brew_prefix)/bin/php" 2>/dev/null)" || return 1
    case "$link" in
        */Cellar/*) printf '%s\n' "$link" | sed -E 's#.*/Cellar/([^/]+)/.*#\1#' ;;
        *) return 1 ;;
    esac
}

# ph_edit_inplace <expr> <file> — in-place sed across GNU (Linux) and BSD (macOS),
# using sudo on Linux where PHP config lives under root-owned /etc/php.
ph_edit_inplace() {
    local expr="$1" file="$2"
    if [ "$(ph_os)" = "macos" ]; then
        sed -i '' "$expr" "$file"
    else
        sudo sed -i "$expr" "$file"
    fi
}

# ph_current_php_version — active PHP version as MAJOR.MINOR (e.g. 8.3).
ph_current_php_version() {
    php -v 2>/dev/null | grep -oE '^PHP [0-9]+\.[0-9]+' | head -1 | grep -oE '[0-9]+\.[0-9]+'
}

# ph_valid_version <version> — true if it looks like MAJOR.MINOR.
ph_valid_version() {
    printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+$'
}

# ph_resolve_version <arg> [--list] — resolve the PHP version from (in order) the
# argument, ./.php-version, or an interactive prompt; trim whitespace/CR and
# validate it. Echoes the version on success; prints an error and returns 1 on an
# empty/invalid value. Prompts and lists are written to stderr so stdout stays
# clean for capture. Pass --list to show installed versions before prompting.
ph_resolve_version() {
    local arg="${1:-}" show_list="${2:-}" version=""
    if [ -n "$arg" ]; then
        version="$arg"
    elif [ -f .php-version ]; then
        version="$(head -n1 .php-version)"
    else
        echo "Please provide the PHP version (e.g. 8.3)" >&2
        if [ "$show_list" = "--list" ]; then
            echo "Available PHP versions:" >&2
            ph_list_versions >&2
        fi
        read -r -p "PHP version: " version
    fi
    # Strip all whitespace (handles trailing space, CR/CRLF, stray blanks).
    version="$(printf '%s' "$version" | tr -d '[:space:]')"
    if ! ph_valid_version "$version"; then
        echo "Invalid or empty PHP version: '${version}' (expected MAJOR.MINOR, e.g. 8.3)" >&2
        return 1
    fi
    printf '%s\n' "$version"
}

# ph_php_confd_dirs <version> — echo the conf.d directories (one per line) where
# extension .ini files live for the given version.
ph_php_confd_dirs() {
    local version="$1"
    if [ "$(ph_os)" = "macos" ]; then
        echo "$(ph_brew_prefix)/etc/php/${version}/conf.d"
    else
        echo "/etc/php/${version}/fpm/conf.d"
        echo "/etc/php/${version}/cli/conf.d"
    fi
}

# ph_php_ini <version> — main php.ini path (macOS: pecl may write the
# zend_extension line here rather than into conf.d).
ph_php_ini() {
    local version="$1"
    if [ "$(ph_os)" = "macos" ]; then
        echo "$(ph_brew_prefix)/etc/php/${version}/php.ini"
    else
        echo "/etc/php/${version}/cli/php.ini"
    fi
}

# ph_restart_fpm <version> — restart PHP-FPM for the given version, best-effort.
# Resolves the real formula/service name so the unversioned `php` (latest) works.
ph_restart_fpm() {
    local version="$1" formula
    if [ "$(ph_os)" = "macos" ]; then
        formula="$(ph_resolve_formula "$version")" || return 0
        [ -n "$formula" ] || return 0
        if brew services list 2>/dev/null | grep -qE "^${formula}[[:space:]]+started"; then
            echo "Restarting ${formula} service..."
            brew services restart "$formula" >/dev/null
        fi
    else
        echo "Restarting php${version}-fpm..."
        sudo systemctl restart "php${version}-fpm" \
            || echo "Could not restart php${version}-fpm (service may not exist)." >&2
    fi
}

# ph_list_versions — print the PHP versions available to switch to, for prompts.
ph_list_versions() {
    if [ "$(ph_os)" = "macos" ]; then
        local f ver
        while read -r f; do
            [ -n "$f" ] || continue
            if [ "$f" = "php" ]; then
                ver="$(ph_brew_latest_version)"
                [ -n "$ver" ] && echo "$ver (latest)"
            else
                echo "${f#php@}"
            fi
        done < <(ph_installed_php_formulae) | sort -u
    else
        ls -A1 /etc/php 2>/dev/null
    fi
}

# ph_xdebug_toggle <enable|disable> [version] — comment/uncomment the Xdebug
# zend_extension line across the version's conf.d files + php.ini, then restart
# FPM if anything changed. Shared by xdebug-enable and xdebug-disable.
ph_xdebug_toggle() {
    local mode="$1" arg="${2:-}"
    local PHP_VERSION expr grep_pat action nochange

    PHP_VERSION="$arg"
    [ -n "$PHP_VERSION" ] || PHP_VERSION="$(ph_current_php_version || true)"
    if ! ph_valid_version "$PHP_VERSION"; then
        echo "Could not determine a valid PHP version. Pass it explicitly, e.g. xdebug-${mode} 8.3" >&2
        return 1
    fi

    # [[:space:]] / \( \) are portable across GNU (Linux) and BSD (macOS) sed.
    case "$mode" in
        enable)
            expr='s/^[[:space:]]*;[[:space:]]*\(zend_extension[[:space:]]*=[[:space:]]*.*xdebug\.so.*\)/\1/'
            grep_pat='^[[:space:]]*;[[:space:]]*zend_extension[[:space:]]*=.*xdebug\.so'
            action="Enabling"
            nochange="No commented-out Xdebug line found (already enabled, or Xdebug not installed)."
            ;;
        disable)
            expr='s/^[[:space:]]*\(zend_extension[[:space:]]*=[[:space:]]*.*xdebug\.so.*\)/;\1/'
            grep_pat='^[[:space:]]*zend_extension[[:space:]]*=.*xdebug\.so'
            action="Disabling"
            nochange="No active Xdebug line found (already disabled, or Xdebug not installed)."
            ;;
        *) echo "ph_xdebug_toggle: unknown mode '${mode}'" >&2; return 2 ;;
    esac

    # Linux edits root-owned files; prime sudo once up front instead of mid-loop.
    if [ "$(ph_os)" = "linux" ]; then sudo -v; fi

    local candidates=() dir f php_ini changed=0
    while read -r dir; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.ini; do
            [ -e "$f" ] && candidates+=("$f")
        done
    done < <(ph_php_confd_dirs "$PHP_VERSION")
    php_ini="$(ph_php_ini "$PHP_VERSION")"
    [ -e "$php_ini" ] && candidates+=("$php_ini")

    for f in ${candidates[@]+"${candidates[@]}"}; do
        if grep -Eq "$grep_pat" "$f"; then
            echo "${action} Xdebug in ${f}..."
            if ph_edit_inplace "$expr" "$f"; then
                changed=1
            else
                echo "WARN: failed to edit ${f}, left unchanged" >&2
            fi
        fi
    done

    if [ "$changed" -eq 0 ]; then
        echo "$nochange"
    else
        ph_restart_fpm "$PHP_VERSION"
    fi
    echo "Done."
}
