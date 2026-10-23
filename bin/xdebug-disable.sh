#!/bin/bash
#
# xdebug-disable [version] — comment out the Xdebug zend_extension line and
# restart PHP-FPM. Defaults to the currently active PHP version.

set -euo pipefail

# Use the repo copy of common.sh when run from a checkout; otherwise the copy
# install.sh puts in its own dir (not ~/.local/bin/lib, which other tools such
# as the Postman CLI overwrite).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PH_LIB="${SCRIPT_DIR}/lib/common.sh"
[ -f "$PH_LIB" ] || PH_LIB="${HOME}/.local/share/php-commandline-helpers/common.sh"
# shellcheck source=lib/common.sh
. "$PH_LIB"

ph_xdebug_toggle disable "${1:-}"
