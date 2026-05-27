#!/bin/bash
# Install steamcmd into the image on amd64 only (steamcmd is x86-only).
# Pattern from https://github.com/JACOBSMILE/tmodloader1.4
set -euo pipefail

if [ "${TARGETARCH:-}" != "amd64" ]; then
  echo "Skipping steamcmd install on ${TARGETARCH:-unknown} (workshop download requires amd64)"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  libc6:i386 \
  libgcc-s1:i386 \
  libstdc++6:i386 \
  zlib1g:i386

BUNDLE=/tmp/steamcmd-bundle
mkdir -p /usr/lib/games/steam/linux32

cp "$BUNDLE/bin/steamcmd.sh" /usr/lib/games/steam/
cp "$BUNDLE/bin/linux32_steamcmd" /usr/lib/games/steam/linux32/steamcmd
cp "$BUNDLE/libstdc++.so.6" /lib/

cat > /usr/bin/steamcmd <<'EOF'
#!/bin/sh
exec /usr/lib/games/steam/steamcmd.sh "$@"
EOF

chmod +x /usr/bin/steamcmd /usr/lib/games/steam/linux32/steamcmd /usr/lib/games/steam/steamcmd.sh

if [ "${BUILDPLATFORM:-}" = "linux/amd64" ]; then
  steamcmd +quit
  echo "steamcmd installed successfully"
else
  echo "steamcmd installed (skipped smoke test on ${BUILDPLATFORM:-unknown} builder)"
fi
