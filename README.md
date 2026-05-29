# tmodloader-docker
Easy to setup tModLoader server using docker with automatic backups.

## Setup

1. Clone repository
```bash 
git clone https://github.com/cubebuc/tmodloader-docker.git
```

2. Change directory
```bash
cd tmodloader-docker
```

3. Add mods (optional) by editing `mods.txt` with [Steam Workshop mod IDs](https://steamcommunity.com/workshop/browse/?appid=1281930) — one ID per line. Comment out a line with `#` to disable a mod.

4. Launch (mods from `mods.txt` download automatically on startup):

```bash
docker compose up -d --build
```

After changing `mods.txt`, run `docker compose up -d --build` or `docker compose restart tml`.

Runs **natively on ARM and amd64** — no emulation. Workshop mods listed in `mods.txt` are downloaded automatically on startup with [DepotDownloader](https://github.com/SteamRE/DepotDownloader) (no Steam account needed).

5. Attach to tModLoader container
```bash
docker attach tml
```
- press <kbd>ENTER</kbd> after attaching

---

Now you can create/delete/start worlds and configure mods using the terminal.
<br>
To detach from the container press <kbd>Ctrl</kbd> + <kbd>P</kbd> + <kbd>Q</kbd>.

---

To shutdown the docker use:
```bash
docker compose down
```

## Configure

### serverconfig.txt
You can directly edit the `serverconfig.txt` file - it will be used for the server if present.
<br>
Paths start with `/app/data`, because that is where root repo folder is mapped in docker volumes.

---

### Backups
Backups are setup using cron and save into `backups/` folder (generates after first backup).
<br>
By default there are hourly and daily backups (keeping 3 and 2 last backups respectively).
<br>
You can edit the `crontab` file to customize them.

Example:
```cron
0 * * * * /app/data/backup.sh hourly 3
```
- `0 * * * *` → cron timing syntax
- `/app/data/backup.sh` → backup script - do NOT change
- `hourly` → subfolder name under backups
- `3` → number of backups to keep in this folder

---
### Updating
To avoid mod incompatibilities updating is done manually, following these simple steps: 
<br>
1. Shutdown the Docker
```bash 
docker compose down
```

2. Update the TML_VERSION
```bash 
export TML_VERSION=v2xxx.y.z
```
where `v.2xxx.y.z` is the target version

3. Re-Build the Docker
```bash 
docker compose build --no-cache
```
4. Re-Launch your Docker
```bash
docker compose up -d
```

---
### Mods
List [Steam Workshop mod IDs](https://steamcommunity.com/workshop/browse/?appid=1281930) in `mods.txt` at the repo root — one ID per line. The ID is the number in the workshop URL (`...?id=2566694256`).

```
# Better Autosave
2566694256

# Calamity (disabled)
#2824688072
```

After editing `mods.txt`, restart the server:

```bash
docker compose restart tml
```

#### How it works

On container start, the entrypoint runs `sync-mods.sh`, which uses [DepotDownloader](https://github.com/SteamRE/DepotDownloader) to download each Workshop item anonymously into a `steamMods/` cache, copies the build matching your server's tModLoader version into `tModLoader/Mods/`, and regenerates `enabled.json` to match `mods.txt`. DepotDownloader is a managed .NET tool, so this runs **natively on ARM (Apple Silicon, Raspberry Pi) and amd64** — no emulation and no Steam account required.

#### Verify mods loaded

```bash
cat tModLoader/Mods/enabled.json
docker compose logs tml 2>&1 | grep '\[mods\]'
```

You should see `[mods] Sync complete` and a non-empty `enabled.json`.

## Recommendations
- By default the `tModLoader` and `backup` folders are going to be owned by root. You can make them user owned by uncommenting the `user` line in `docker-compose.yml` and `chown` line in `backup.sh`. Don't forget to change the ids to match your user and reset docker.
- Add [Better Autosave](https://steamcommunity.com/sharedfiles/filedetails/?id=2566694256) mod - by default it saves the world only once per Terraria day.
- Specifying `world` in the `serverconfig.txt` disables interactive mode and starts the server directly (omitting it starts interactive mode).
