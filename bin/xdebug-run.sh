#!/bin/bash
#
# xdebug-run <command...> — run a command with Xdebug step-debugging triggered
# for that one invocation only (sets XDEBUG_TRIGGER). Your IDE must be listening
# for debug connections on port 9003, and Xdebug must be enabled (xdebug-enable).
#
#   xdebug-run php listings.test
#   xdebug-run ./artisan migrate

set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: xdebug-run <command> [args...]   e.g. xdebug-run php listings.test" >&2
    exit 1
fi

export XDEBUG_TRIGGER=1
exec "$@"
