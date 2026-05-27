#!/bin/sh
set -eu

DATA_DIR="${DATA_DIR:-/app/data}"
MODS_FILE="${MODS_FILE:-$DATA_DIR/mods.txt}"
MODS_DIR="$DATA_DIR/tModLoader/Mods"
INSTALL_TXT="$MODS_DIR/install.txt"
ENABLED_JSON="$MODS_DIR/enabled.json"
STEAMCMD="${STEAMCMD:-/app/steamcmd/steamcmd.sh}"
WORKSHOP_APP=1281930
WORKSHOP_ROOT="$DATA_DIR/steamapps/workshop/content/$WORKSHOP_APP"

mkdir -p "$MODS_DIR"

if [ ! -f "$MODS_FILE" ]; then
    echo "No mods.txt found at $MODS_FILE — skipping mod sync"
    exit 0
fi

# Collect workshop IDs: one per line, # comments and blank lines ignored
MOD_IDS=""
while IFS= read -r line || [ -n "$line" ]; do
  line=$(printf '%s' "$line" | sed 's/#.*//' | tr -d ' \t\r')
  [ -z "$line" ] && continue
  MOD_IDS="$MOD_IDS $line"
done < "$MODS_FILE"

# Write install.txt for workshop downloads
: > "$INSTALL_TXT"
for id in $MOD_IDS; do
  echo "$id" >> "$INSTALL_TXT"
done

if [ -z "$MOD_IDS" ]; then
    echo "[]" > "$ENABLED_JSON"
    echo "No mods listed in mods.txt"
    exit 0
fi

if [ ! -x "$STEAMCMD" ] && [ ! -f "$STEAMCMD" ]; then
    echo "steamcmd not found at $STEAMCMD — cannot download workshop mods" >&2
    exit 1
fi

echo "Downloading workshop mods from mods.txt..."
steamcmd_command=""
for id in $MOD_IDS; do
  steamcmd_command="$steamcmd_command +workshop_download_item $WORKSHOP_APP $id"
done

# shellcheck disable=SC2086
"$STEAMCMD" +force_install_dir "$DATA_DIR" +login anonymous $steamcmd_command +quit

echo "Building enabled.json..."
NAMES_FILE=$(mktemp)
for id in $MOD_IDS; do
  tmod=$(find "$WORKSHOP_ROOT/$id" -name "*.tmod" 2>/dev/null | head -n 1 || true)
  if [ -z "$tmod" ]; then
    echo "Warning: no .tmod found for workshop id $id (download may have failed)" >&2
    continue
  fi
  python3 /app/extract-mod-name.py "$tmod" >> "$NAMES_FILE"
done
python3 -c "import json, pathlib; names=[l.strip() for l in pathlib.Path('$NAMES_FILE').read_text().splitlines() if l.strip()]; pathlib.Path('$ENABLED_JSON').write_text(json.dumps(names, indent=2) + '\n')"
rm -f "$NAMES_FILE"

echo "Mod sync complete ($(wc -l < "$INSTALL_TXT" | tr -d ' ') workshop item(s))"
