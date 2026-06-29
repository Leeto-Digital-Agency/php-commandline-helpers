#!/bin/bash
#
# xdebug-enable [version] — uncomment the Xdebug zend_extension line and restart
# PHP-FPM. Defaults to the currently active PHP version.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

ph_xdebug_toggle enable "${1:-}"
