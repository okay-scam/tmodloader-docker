#!/bin/bash
set -e

/app/sync-mods.sh

cd /app
exec "$@"
