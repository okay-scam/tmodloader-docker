# tmodloader-docker
tModLoader dedicated server in Docker, with automatic Steam Workshop mod installation and world backups. Runs on ARM and amd64.

## Setup

1. Clone and enter the repo:
```bash
git clone https://github.com/okay-scam/tmodloader-docker.git
cd tmodloader-docker
```

2. *(Optional)* Add mods: copy `mods.txt.example` to `mods.txt` and list [Steam Workshop mod IDs](https://steamcommunity.com/workshop/browse/?appid=1281930), one per line. (If you skip this, `mods.txt` is created from the example on first launch.)

3. Launch:
```bash
docker compose up -d --build
```

4. Attach to the server console:
```bash
docker attach tml
```
Press <kbd>ENTER</kbd> after attaching. Detach with <kbd>Ctrl</kbd>+<kbd>P</kbd> then <kbd>Ctrl</kbd>+<kbd>Q</kbd>.

Stop everything:
```bash
docker compose down
```

## Mods
List Workshop IDs in `mods.txt`, one per line. Comment a line with `#` to disable that mod.

```
# Better Autosave
2566694256

# Calamity (disabled)
#2824688072
```

Apply changes:
```bash
docker compose up -d --build
```

## Server config
Server settings live in `serverconfig.txt`, created from `serverconfig.txt.example` on first launch. The template sets a `world`, so the server boots headless and starts listening; edit it to change the world, password, or max players.

Deploy-specific values — build version, published host port, timezone — go in `.env`:
```bash
cp .env.example .env
```

## Backups
Worlds in `tModLoader/Worlds/` are archived to `backups/` every 15 minutes (7-day retention). Adjust the schedule/retention under the `backup` service in `docker-compose.yml`.

Restore:
```bash
mkdir -p /tmp/restore && tar -xzf backups/tmodloader-latest.tar.gz -C /tmp/restore
docker compose stop tml
cp /tmp/restore/backup/Worlds/<world>.wld tModLoader/Worlds/
docker compose start tml
```

## Updating tModLoader
Set `TML_VERSION` in `.env` to a newer [release tag](https://github.com/tModLoader/tModLoader/releases) (note the zero-padded month, e.g. `v2026.03.3.0`), then rebuild:
```bash
docker compose up -d --build
```
