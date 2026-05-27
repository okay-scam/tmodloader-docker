#!/bin/bash
set -e

if [ "${SKIP_MOD_SYNC:-0}" != "1" ]; then
  /app/sync-mods.sh
fi

cd /app
exec "$@"
