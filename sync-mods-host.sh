#!/bin/bash
# Run workshop downloads on the host when in-container steamcmd crashes.
# Requires steamcmd on the host (Debian/Ubuntu amd64): sudo apt install steamcmd
set -euo pipefail

cd "$(dirname "$0")"
DATA_DIR="$PWD"
STEAMCMD_BIN="${STEAMCMD:-$(command -v steamcmd || true)}"
WORKSHOP_APP=1281930

if [ -z "$STEAMCMD_BIN" ]; then
  echo "Install steamcmd on the host first, e.g.: sudo apt install steamcmd" >&2
  exit 1
fi

if [ ! -f mods.txt ]; then
  echo "mods.txt not found in $DATA_DIR" >&2
  exit 1
fi

steamcmd_command=""
while IFS= read -r line || [ -n "$line" ]; do
  line=$(printf '%s' "$line" | sed 's/#.*//' | tr -d ' \t\r')
  [ -z "$line" ] && continue
  steamcmd_command="$steamcmd_command +workshop_download_item $WORKSHOP_APP $line validate"
done < mods.txt

if [ -z "$steamcmd_command" ]; then
  echo "No mod IDs in mods.txt"
  exit 0
fi

echo "Downloading workshop mods with host steamcmd..."
# shellcheck disable=SC2086
"$STEAMCMD_BIN" +force_install_dir "$DATA_DIR" +login anonymous $steamcmd_command +quit

echo "Building enabled.json in container..."
docker run --rm --platform linux/amd64 \
  -v "$DATA_DIR:/app/data" \
  --entrypoint /app/sync-mods.sh \
  tmodloader --enabled-only

echo "Done. Restart the server: docker compose restart tml"
