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

# ph_mkdir / ph_write_file / ph_remove_file — filesystem ops that use sudo on
# Linux (PHP config lives under root-owned /etc/php) and run directly on macOS
# (the Homebrew prefix is user-owned). ph_write_file reads content from stdin.
ph_mkdir() {
    if [ "$(ph_os)" = "macos" ]; then mkdir -p "$1"; else sudo mkdir -p "$1"; fi
}
ph_write_file() {
    if [ "$(ph_os)" = "macos" ]; then cat > "$1"; else sudo tee "$1" >/dev/null; fi
}
ph_remove_file() {
    if [ "$(ph_os)" = "macos" ]; then rm -f "$1"; else sudo rm -f "$1"; fi
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

# Name of the conf.d file this tool owns. The `zz-` prefix makes it load LAST so
# its xdebug.mode wins over any default, and it is the single source of truth for
# the enabled/disabled state (its presence + content), so php.ini is never edited.
PH_XDEBUG_INI="zz-xdebug.ini"

# ph_xdebug_loaded_externally <version> — true if an UNCOMMENTED Xdebug
# zend_extension line is already present in php.ini or another conf.d file (e.g.
# the line pecl writes into php.ini), so we must not load it again ourselves.
ph_xdebug_loaded_externally() {
    local version="$1" dir f
    if grep -Eq '^[[:space:]]*zend_extension[[:space:]]*=.*xdebug\.so' "$(ph_php_ini "$version")" 2>/dev/null; then
        return 0
    fi
    while read -r dir; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.ini; do
            [ -e "$f" ] || continue
            [ "$(basename "$f")" = "$PH_XDEBUG_INI" ] && continue
            grep -Eq '^[[:space:]]*zend_extension[[:space:]]*=.*xdebug\.so' "$f" && return 0
        done
    done < <(ph_php_confd_dirs "$version")
    return 1
}

# ph_strip_xdebug_load_from_ini <version> — remove any Xdebug zend_extension line
# (commented or active) that pecl injected into php.ini, so Xdebug loading is
# owned by the conf.d file instead and php.ini stays clean. No-op if absent.
ph_strip_xdebug_load_from_ini() {
    local version="$1" ini expr
    ini="$(ph_php_ini "$version")"
    [ -f "$ini" ] || return 0
    expr='/^[[:space:]]*;?[[:space:]]*zend_extension[[:space:]]*=.*xdebug\.so/d'
    if [ "$(ph_os)" = "macos" ]; then
        sed -i '' -E "$expr" "$ini"
    else
        sudo sed -i -E "$expr" "$ini"
    fi
}

# ph_xdebug_toggle <enable|disable> [version] — manage the tool-owned
# conf.d/zz-xdebug.ini. enable writes a working debug config (mode=debug + a
# zend_extension load line only if nothing else loads Xdebug); disable sets
# xdebug.mode=off so Xdebug goes inert no matter how it is loaded. php.ini is
# never touched. Restarts FPM afterwards. Shared by xdebug-enable/xdebug-disable.
ph_xdebug_toggle() {
    local mode="$1" arg="${2:-}" version dir managed

    case "$mode" in
        enable|disable) ;;
        *) echo "ph_xdebug_toggle: unknown mode '${mode}'" >&2; return 2 ;;
    esac

    version="$arg"
    [ -n "$version" ] || version="$(ph_current_php_version || true)"
    if ! ph_valid_version "$version"; then
        echo "Could not determine a valid PHP version. Pass it explicitly, e.g. xdebug-${mode} 8.3" >&2
        return 1
    fi

    # Linux writes under root-owned /etc/php; prime sudo once up front.
    if [ "$(ph_os)" = "linux" ]; then sudo -v; fi

    while read -r dir; do
        ph_mkdir "$dir"
        managed="${dir}/${PH_XDEBUG_INI}"
        if [ "$mode" = "enable" ]; then
            {
                echo "; Managed by php-commandline-helpers (xdebug-enable / xdebug-disable). Do not edit."
                # Only load Xdebug here if nothing else already does (avoid double-load).
                ph_xdebug_loaded_externally "$version" || echo "zend_extension=xdebug.so"
                echo "xdebug.mode=debug"
                # 'trigger' so only opted-in runs debug (XDEBUG_TRIGGER / IDE
                # cookie); plain `php` stays fast and is never hijacked.
                echo "xdebug.start_with_request=trigger"
                echo "xdebug.client_host=localhost"
                echo "xdebug.client_port=9003"
            } | ph_write_file "$managed"
        else
            {
                echo "; Managed by php-commandline-helpers (xdebug-enable / xdebug-disable). Do not edit."
                echo "xdebug.mode=off"
            } | ph_write_file "$managed"
        fi
    done < <(ph_php_confd_dirs "$version")

    if [ "$mode" = "enable" ]; then
        echo "Xdebug ENABLED for PHP ${version} (mode=debug, port 9003)."
    else
        echo "Xdebug DISABLED for PHP ${version} (mode=off)."
    fi
    ph_restart_fpm "$version"
    echo "Done."
}
