#!/bin/bash
# serverconfig.txt is gitignored so user edits survive a pull; seed it from the tracked
# template on first run.
DATA_DIR="${DATA_DIR:-/app/data}"
if [[ ! -f "$DATA_DIR/serverconfig.txt" && -f "$DATA_DIR/serverconfig.txt.example" ]]; then
  cp "$DATA_DIR/serverconfig.txt.example" "$DATA_DIR/serverconfig.txt"
  echo "[config] Created serverconfig.txt from serverconfig.txt.example."
fi

# Sync Workshop mods from mods.txt, then start the server. A mod-sync failure must not
# stop the server from booting, so we don't abort the entrypoint on its exit code.
/app/sync-mods.sh || echo "[mods] sync-mods.sh failed — starting server without mod changes." >&2

cd /app
exec "$@"
