#!/bin/bash
# Workshop mod sync — based on https://github.com/JACOBSMILE/tmodloader1.4 entrypoint.sh
set -euo pipefail

DATA_DIR="${DATA_DIR:-/app/data}"
MODS_FILE="${MODS_FILE:-$DATA_DIR/mods.txt}"
MODS_DIR="$DATA_DIR/tModLoader/Mods"
ENABLED_JSON="$MODS_DIR/enabled.json"
STEAM_MODS_DIR="$DATA_DIR/steamMods"
WORKSHOP_APP=1281930
WORKSHOP_ROOT="$STEAM_MODS_DIR/steamapps/workshop/content/$WORKSHOP_APP"

mkdir -p "$MODS_DIR" "$STEAM_MODS_DIR"

if [ ! -f "$MODS_FILE" ]; then
  echo "[mods] No mods.txt at $MODS_FILE — skipping"
  exit 0
fi

MOD_IDS=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [ -z "$line" ] && continue
  MOD_IDS+=("$line")
done < "$MODS_FILE"

if [ "${#MOD_IDS[@]}" -eq 0 ]; then
  echo "[]" > "$ENABLED_JSON"
  echo "[mods] No mod IDs in mods.txt"
  exit 0
fi

can_download() {
  command -v steamcmd >/dev/null 2>&1 && [ "$(uname -m)" = "x86_64" ]
}

if ! can_download && [ "${#MOD_IDS[@]}" -gt 0 ]; then
  if ! command -v steamcmd >/dev/null 2>&1; then
    echo "[mods] steamcmd is not in this image — rebuild with: docker compose build --no-cache" >&2
  elif [ "$(uname -m)" != "x86_64" ]; then
    echo "[mods] Workshop download needs linux/amd64 (current: $(uname -m))" >&2
    echo "[mods] Rebuild and run with platform linux/amd64 in docker-compose.yml, or copy steamMods/ from an amd64 host." >&2
  fi
fi

if can_download; then
  echo "[mods] Downloading ${#MOD_IDS[@]} workshop mod(s)..."
  workshop_cmds=""
  for id in "${MOD_IDS[@]}"; do
    workshop_cmds+=" +workshop_download_item $WORKSHOP_APP $id"
  done
  # shellcheck disable=SC2086
  steamcmd +force_install_dir "$STEAM_MODS_DIR" +login anonymous $workshop_cmds +quit
fi

echo "[mods] Building enabled.json..."
names=()
missing=0
for id in "${MOD_IDS[@]}"; do
  content_dir=$(ls -d "$WORKSHOP_ROOT/$id"/*/ 2>/dev/null | tail -n 1 || true)
  if [ -z "$content_dir" ]; then
    echo "[mods] WARNING: workshop id $id not found under $WORKSHOP_ROOT" >&2
    missing=$((missing + 1))
    continue
  fi
  tmod_file=$(ls -1 "$content_dir"*.tmod 2>/dev/null | head -n 1 || true)
  if [ -z "$tmod_file" ]; then
    echo "[mods] WARNING: no .tmod in $content_dir" >&2
    missing=$((missing + 1))
    continue
  fi
  modname=$(basename "$tmod_file" .tmod)
  names+=("$modname")
  echo "[mods] Enabled $modname ($id)"
done

if [ "${#names[@]}" -eq 0 ]; then
  echo "[mods] ERROR: no mods could be enabled. On ARM, copy steamMods/ from amd64 or add .tmod files manually." >&2
  exit 1
fi

if [ "$missing" -gt 0 ] && ! can_download; then
  echo "[mods] WARNING: $missing mod(s) missing workshop files (expected on ARM without a prior amd64 sync)" >&2
fi

{
  echo "["
  for i in "${!names[@]}"; do
    if [ "$i" -lt $((${#names[@]} - 1)) ]; then
      printf '  "%s",\n' "${names[$i]}"
    else
      printf '  "%s"\n' "${names[$i]}"
    fi
  done
  echo "]"
} > "$ENABLED_JSON"

echo "[mods] Sync complete"
