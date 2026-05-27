# Deploying heidrun-spirit

## Why there's no Dockerfile

The bot talks to Hotline servers through `HeidrunCore`'s `HotlineNetworkClient`,
which is built on Apple's **Network framework** (`NWConnection`) and is
therefore **Darwin-only** — its whole source is behind `#if canImport(Network)`.
Docker containers are Linux, where that client **compiles out entirely**; there
is no SwiftNIO/Linux Hotline *client* transport in `HeidrunCore` (only the
server side runs on Linux, which is why `heidrun-server` ships a Dockerfile and
this doesn't).

So heidrun-spirit deploys as a **native macOS process**, run under `launchd`.

**Want it on a Linux host (e.g. next to `heidrun-server`)?** That needs the
Hotline client transport ported to SwiftNIO first — a real piece of work in
`heidrun-protocol`, not a packaging change. Tracked as a future option; until
then, run the bot on a Mac.

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
