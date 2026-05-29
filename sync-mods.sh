#!/usr/bin/env bash
# Download Steam Workshop mods listed in mods.txt and enable them for the tModLoader server.
# Uses DepotDownloader (managed .NET, runs native on any arch) with an anonymous Steam login,
# then copies the build matching this server's tModLoader version into the Mods folder and
# regenerates enabled.json. Remove/comment a line in mods.txt to disable that mod.
set -uo pipefail

DATA_DIR="${DATA_DIR:-/app/data}"
MODS_FILE="$DATA_DIR/mods.txt"
MODS_DIR="$DATA_DIR/tModLoader/Mods"
ENABLED_JSON="$MODS_DIR/enabled.json"
WORKSHOP_APP=1281930
# DepotDownloader caches each item here (incremental re-downloads); kept out of git via .gitignore.
WORKSHOP_ROOT="$DATA_DIR/steamMods/steamapps/workshop/content/$WORKSHOP_APP"
DD="${DEPOTDOWNLOADER:-/opt/depotdownloader/DepotDownloader}"

# Server tModLoader version as YEAR.MONTH (e.g. v2025.10.3.1 -> 2025.10), used to pick a
# compatible mod build. The release tag zero-pads the month (v2026.03.3.0) but workshop
# build folders do not (2026.3), so strip leading zeros to keep `sort -V` comparisons honest.
# Empty (unknown) means "use the newest build available".
RAW_VER="$(printf '%s' "${TML_VERSION:-}" | sed 's/^v//' | cut -d. -f1-2)"
if [[ -n "$RAW_VER" ]]; then
  SERVER_VER="$(awk -F. '{printf "%d.%d", $1, $2}' <<<"$RAW_VER")"
else
  SERVER_VER=""
fi

mkdir -p "$MODS_DIR"

# Parse mod IDs: drop everything after '#', strip whitespace, keep digit-only lines.
MOD_IDS=()
if [[ -f "$MODS_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ "$line" =~ ^[0-9]+$ ]] && MOD_IDS+=("$line")
  done < "$MODS_FILE"
fi

if [[ ${#MOD_IDS[@]} -eq 0 ]]; then
  echo "[mods] No mod IDs in mods.txt — server will start with no mods enabled."
  printf '[]\n' > "$ENABLED_JSON"
  exit 0
fi

# A workshop item contains one .tmod build per tModLoader version, in YEAR.MONTH folders.
# Pick the highest build folder that is <= the server version.
pick_build() {
  local item_dir="$1" chosen=""
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    if [[ -z "$SERVER_VER" || "$(printf '%s\n%s\n' "$v" "$SERVER_VER" | sort -V | head -n1)" == "$v" ]]; then
      chosen="$v"
    fi
  done < <(find "$item_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
             | grep -E '^[0-9]+\.[0-9]+$' | sort -V)
  printf '%s' "$chosen"
}

echo "[mods] Syncing ${#MOD_IDS[@]} workshop mod(s) (server tML ${SERVER_VER:-unknown})..."

names=()
missing=0
for id in "${MOD_IDS[@]}"; do
  item_dir="$WORKSHOP_ROOT/$id"
  # Skip the Steam connection if a build compatible with this server version is already cached.
  # To force a re-check/update, delete the item's folder under steamMods/ (or set MODS_FORCE=1).
  if [[ "${MODS_FORCE:-0}" != "1" && -n "$(pick_build "$item_dir")" ]]; then
    echo "[mods] $id already cached — skipping download."
  else
    echo "[mods] Downloading workshop item $id..."
    "$DD" -app "$WORKSHOP_APP" -pubfile "$id" -dir "$item_dir" \
      || echo "[mods] NOTE: DepotDownloader exited non-zero for $id — will verify below." >&2
  fi
  build="$(pick_build "$item_dir")"
  if [[ -z "$build" ]]; then
    echo "[mods] WARNING: no build compatible with tML ${SERVER_VER:-?} for id $id — skipping." >&2
    missing=$((missing + 1)); continue
  fi
  tmod="$(find "$item_dir/$build" -maxdepth 1 -name '*.tmod' 2>/dev/null | head -n1)"
  if [[ -z "$tmod" ]]; then
    echo "[mods] WARNING: no .tmod for id $id (bad ID or download failed) — skipping." >&2
    missing=$((missing + 1)); continue
  fi
  name="$(basename "$tmod" .tmod)"
  cp -f "$tmod" "$MODS_DIR/$name.tmod"
  names+=("$name")
  echo "[mods] Enabled $name ($id) [build $build]"
done

{
  printf '[\n'
  for i in "${!names[@]}"; do
    sep=,
    [[ $i -eq $((${#names[@]} - 1)) ]] && sep=
    printf '  "%s"%s\n' "${names[$i]}" "$sep"
  done
  printf ']\n'
} > "$ENABLED_JSON"

echo "[mods] Wrote $ENABLED_JSON — ${#names[@]} enabled, $missing missing."
echo "[mods] Sync complete"
