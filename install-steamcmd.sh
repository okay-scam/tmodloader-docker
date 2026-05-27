#!/bin/bash
# Install steamcmd into the image on amd64 only (steamcmd is x86-only).
# Pattern from https://github.com/JACOBSMILE/tmodloader1.4
set -euo pipefail

if [ "${TARGETARCH:-}" != "amd64" ]; then
  echo "Skipping steamcmd install on ${TARGETARCH:-unknown} (workshop download requires amd64)"
  exit 0
fi

BUNDLE=/tmp/steamcmd-bundle
mkdir -p /usr/lib/games/steam /lib/i386-linux-gnu

cp "$BUNDLE/bin/steamcmd.sh" /usr/lib/games/steam/
cp "$BUNDLE/bin/linux32_steamcmd" /usr/lib/games/steam/steamcmd
cp "$BUNDLE/bin/steamcmd_wrapper" /usr/bin/steamcmd
cp -a "$BUNDLE/i386-lib/"* /lib/i386-linux-gnu/
cp "$BUNDLE/libstdc++.so.6" /lib/

chmod +x /usr/bin/steamcmd /usr/lib/games/steam/steamcmd /usr/lib/games/steam/steamcmd.sh
steamcmd +quit

echo "steamcmd installed successfully"
