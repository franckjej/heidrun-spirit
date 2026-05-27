# Deploying heidrun-spirit

heidrun-spirit is an outbound Hotline client built on the cross-platform
`NIOHotlineClient` (SwiftNIO), so it runs on **Linux (Docker)** and **macOS
(launchd)**. Pick whichever fits your host.

## Docker (Linux)

The repo ships a multi-stage `Dockerfile` and a `docker-compose.yml`. The build
fetches the private `heidrun-protocol` SPM package, authenticated with a GitHub
token passed as a BuildKit secret — `gh auth token` emits one once you've run
`gh auth login`.

```bash
cd heidrun-spirit

# Set the server the bot connects to in docker-compose.yml
# (HEIDRUN_SPIRIT_HOST), then:
DOCKER_BUILDKIT=1 GH_TOKEN="$(gh auth token)" \
  docker compose up -d --build

# Logs (connect/login/reconnect lines):
docker logs -f heidrun-spirit

# Stop:
docker compose down
```

The MegaHAL **brain persists** in the `spirit-brain` named volume and is seeded
from the bundled training data on first run. To reset the bot's "personality":

```bash
docker compose down
docker volume rm heidrun-spirit_spirit-brain
```

**Co-locating with heidrun-server** on the same host: uncomment the `networks:`
stanzas in `docker-compose.yml` and set `HEIDRUN_SPIRIT_HOST: heidrun-server`
(port `5500`) so the bot reaches the server over the internal docker network —
no public exposure needed. See the comments in `docker-compose.yml`.

The container connects out and has no published ports. Configuration is entirely
environment variables (see the table at the bottom); the compose file lists every
one with its default.

## macOS deployment (launchd)

### 1. Build a release binary

```bash
cd heidrun-spirit
swift build -c release
```

### 2. Install the binary **and its resource bundle**

The MegaHAL seed brain ships as a SwiftPM resource bundle that `Bundle.module`
locates **next to the executable** — so the bundle must travel with the binary:

```bash
sudo install -d /usr/local/bin
sudo install -m 0755 .build/release/heidrun-spirit /usr/local/bin/
sudo cp -R .build/release/heidrun-spirit_SpiritKit.bundle /usr/local/bin/
sudo install -d /usr/local/var/heidrun-spirit /usr/local/var/log
```

### 3. Install + configure the launchd job

```bash
sudo install -m 0644 \
  deploy/launchd/org.tastybytes.heidrun-spirit.plist \
  /Library/LaunchDaemons/
```

Edit `/Library/LaunchDaemons/org.tastybytes.heidrun-spirit.plist` and set
`HEIDRUN_SPIRIT_HOST` (and `LOGIN`/`PASSWORD` if the bot needs an account).

### 4. Load it

```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/org.tastybytes.heidrun-spirit.plist
```

Tail the logs:

```bash
tail -f /usr/local/var/log/heidrun-spirit.err.log   # connect/login/reconnect lines
```

Stop it:

```bash
sudo launchctl bootout system/org.tastybytes.heidrun-spirit
```

## Configuration

All via environment variables (set in the plist's `EnvironmentVariables`):

| Variable | Meaning | Default |
|---|---|---|
| `HEIDRUN_SPIRIT_HOST` | server hostname / IP | *(required)* |
| `HEIDRUN_SPIRIT_PORT` | TCP port | `5500` |
| `HEIDRUN_SPIRIT_LOGIN` | account login (empty = guest) | `""` |
| `HEIDRUN_SPIRIT_PASSWORD` | account password | `""` |
| `HEIDRUN_SPIRIT_NICK` | nickname | `Heidrun's Spirit` |
| `HEIDRUN_SPIRIT_ICON` | numeric Hotline icon ID | `0` |
| `HEIDRUN_SPIRIT_EMOJI` | emoji avatar | *(none)* |
| `HEIDRUN_SPIRIT_TLS` | `1`/`true` for TLS (system-trust only) | `false` |
| `HEIDRUN_SPIRIT_BRAIN_PATH` | writable brain directory | `./brain` |
| `HEIDRUN_SPIRIT_AUTOSAVE` | save brain every N replies | `25` |
| `HEIDRUN_SPIRIT_LOG_LEVEL` | `debug`/`info`/`error` | `info` |

The brain directory is seeded from the bundled training data on first run and
written back as the bot learns. To reset the bot's "personality", stop it and
`rm -rf "$HEIDRUN_SPIRIT_BRAIN_PATH"`.
