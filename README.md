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

Works on **ARM and amd64** (same as the original cubebuc image). Workshop downloads via SteamCMD run on **amd64 only**; on ARM, sync `steamMods/` from an amd64 machine once, or copy `.tmod` files into `tModLoader/Mods/` manually.

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

Workshop files are stored in `steamMods/` (same layout as [jacobsmile/tmodloader1.4](https://github.com/JACOBSMILE/tmodloader1.4)). `tModLoader/Mods/enabled.json` is generated on each start.

#### Verify mods loaded

```bash
cat tModLoader/Mods/enabled.json
find steamMods/steamapps/workshop/content/1281930 -name '*.tmod'
docker compose logs tml 2>&1 | grep '\[mods\]'
```

You should see `[mods] Sync complete` and a non-empty `enabled.json`.

#### ARM hosts (Apple Silicon, Raspberry Pi, etc.)

The game server runs natively on ARM. SteamCMD (workshop download) is x86-only, so on first setup either:

1. Run `docker compose up -d --build` once on an **amd64** machine (or with `DOCKER_DEFAULT_PLATFORM=linux/amd64`) so `steamMods/` is populated, then copy the whole project folder to ARM, or  
2. Copy `.tmod` files into `tModLoader/Mods/` and set `enabled.json` by hand (original cubebuc workflow).

On ARM, logs will show `Skipping workshop download` — that is expected if `steamMods/` is already present.

## Recommendations
- By default the `tModLoader` and `backup` folders are going to be owned by root. You can make them user owned by uncommenting the `user` line in `docker-compose.yml` and `chown` line in `backup.sh`. Don't forget to change the ids to match your user and reset docker.
- Add [Better Autosave](https://steamcommunity.com/sharedfiles/filedetails/?id=2566694256) mod - by default it saves the world only once per Terraria day.
- Specifying `world` in the `serverconfig.txt` disables interactive mode and starts the server directly (omitting it starts interactive mode).
