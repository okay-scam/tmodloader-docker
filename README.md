# tmodloader-docker
tModLoader dedicated server in Docker, with automatic Steam Workshop mod installation and world backups. Runs on ARM and amd64.

## Setup

1. Clone and enter the repo:
```bash
git clone https://github.com/okay-scam/tmodloader-docker.git
cd tmodloader-docker
```

2. *(Optional)* Add mods: put [Steam Workshop mod IDs](https://steamcommunity.com/workshop/browse/?appid=1281930) in `mods.txt`, one per line.

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
Edit `serverconfig.txt`. Setting `world` there starts the server directly; omitting it starts the interactive console.

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
```bash
docker compose down
export TML_VERSION=v2xxx.y.z
docker compose up -d --build
```
