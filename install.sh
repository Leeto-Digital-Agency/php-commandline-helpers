#!/bin/bash
#
# install.sh — install the php-commandline-helpers on macOS (Homebrew) or
# Linux (apt). Copies the commands into ~/.local/bin and makes sure that dir
# is on your PATH. Safe to re-run (idempotent).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"

os="linux"
[ "$(uname -s)" = "Darwin" ] && os="macos"

if [ "$os" = "macos" ] && ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS but was not found." >&2
    echo "Install it from https://brew.sh and re-run this script." >&2
    exit 1
fi

echo "Installing helpers to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}/lib"

# Commands are installed without the .sh extension so they read as plain commands.
for name in switch-php install-php xdebug-enable xdebug-disable xdebug-run; do
    cp "${REPO_DIR}/bin/${name}.sh" "${INSTALL_DIR}/${name}"
    chmod +x "${INSTALL_DIR}/${name}"
done
cp "${REPO_DIR}/bin/lib/common.sh" "${INSTALL_DIR}/lib/common.sh"

# Pick the right shell rc file.
case "$(basename "${SHELL:-/bin/bash}")" in
    zsh)  RC_FILE="${HOME}/.zshrc" ;;
    bash) RC_FILE="${HOME}/.bashrc" ;;
    *)    [ "$os" = "macos" ] && RC_FILE="${HOME}/.zshrc" || RC_FILE="${HOME}/.bashrc" ;;
esac

# Idempotently ensure ~/.local/bin is on PATH. Skip if our marker is already
# there, or if the rc already exports .local/bin via an uncommented line.
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
MARKER='# php-commandline-helpers'
already_on_path() {
    [ -f "$RC_FILE" ] || return 1
    grep -qF "$MARKER" "$RC_FILE" && return 0
    grep -qE '^[[:space:]]*export[[:space:]]+PATH=.*\.local/bin' "$RC_FILE"
}
if already_on_path; then
    echo "~/.local/bin already on PATH in ${RC_FILE}"
else
    {
        echo ""
        echo "$MARKER"
        echo "$PATH_LINE"
    } >> "$RC_FILE"
    echo "Added ~/.local/bin to PATH in ${RC_FILE}"
fi

echo ""
echo "Done. Installed: switch-php, install-php, xdebug-enable, xdebug-disable"
echo "Restart your shell or run: source ${RC_FILE}"
if [ "$os" = "macos" ]; then
    echo "On macOS, Xdebug is installed per-version via pecl by 'install-php'."
fi
