#!/bin/bash
# Sync Workshop mods from mods.txt, then start the server. A mod-sync failure must not
# stop the server from booting, so we don't abort the entrypoint on its exit code.
/app/sync-mods.sh || echo "[mods] sync-mods.sh failed — starting server without mod changes." >&2

cd /app
exec "$@"
