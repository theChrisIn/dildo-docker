#!/usr/bin/env bash
set -eo pipefail

if [ $# -eq 0 ]; then
    exec java -jar /opt/viperserver.jar --help
fi

if command -v "$1" >/dev/null 2>&1 && [ ! -f "$1" ]; then
    exec "$@"
fi

# Real server start: launch the version shim in the background first, since
# ViperServer's own HTTP API has no version/health endpoint of its own.
dildo-docker-shim &

exec java -jar /opt/viperserver.jar "$@"
