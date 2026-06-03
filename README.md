<pre align="center">
    __         _     __                               _      _ __ 
   / /_  ___  (_)___/ /______  ______     _________  (_)____(_) /_
  / __ \/ _ \/ / __  / ___/ / / / __ \   / ___/ __ \/ / ___/ / __/
 / / / /  __/ / /_/ / /  / /_/ / / / /  (__  ) /_/ / / /  / / /_  
/_/ /_/\___/_/\__,_/_/   \__,_/_/ /_/  /____/ .___/_/_/  /_/\__/  
                                           /_/                    
</pre>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.2-orange.svg" alt="Swift 6.2"></a>
  <img src="https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-blue.svg" alt="macOS | Linux">
  <a href="https://www.gnu.org/licenses/gpl-2.0.html"><img src="https://img.shields.io/badge/License-GPLv2-blue.svg" alt="License: GPL v2"></a>
</p>

# heidrun-spirit

A standalone **Hotline chatterbot** powered by the classic [**MegaHAL**](https://megahal.alioth.debian.org/) Markov engine (© 1998 Jason Hutchens, GPL-2.0). A Swift revival of the 2002 "Heidrun's Spirit" module — logs into a Hotline server and talks nonsense to whoever's listening.

The 1998 C engine compiles untouched as a SwiftPM C target; a thin Swift actor wraps it. The Hotline client side rides [`HeidrunNIOClient`](https://github.com/franckjej/heidrun-protocol), so the bot builds and runs on **macOS** and **Linux** from the same source.

## What it does

- Joins a Hotline server's public chat with a configurable nick + icon + emoji
- Replies to every chat line it sees (one reply per peer line; never to itself)
- Learns from what it reads — the MegaHAL brain accumulates and persists between restarts
- Auto-reconnects with capped exponential backoff if the connection drops
- Filters its own echoes by nickname so it doesn't fall into a self-reply loop

It's an outbound client; no published ports. Point it at any Hotline server (classic, heidrun-server, mobius, mierau's) and watch it babble.

## Quick start

### Docker (Linux)

```bash
docker compose up -d --build
docker logs -f heidrun-spirit
```

Set `HEIDRUN_SPIRIT_HOST` in `docker-compose.yml` first. The MegaHAL brain persists in the `spirit-brain` named volume and seeds from the bundled training data on first run. Reset the bot's personality by removing the volume.

### macOS (launchd)

See [`deploy/`](deploy/README.md) for the LaunchDaemon plist + install steps.

### Local (development)

```bash
swift build -c release
HEIDRUN_SPIRIT_HOST=hotline.example.com .build/release/heidrun-spirit
```

## Configuration

All env-var driven. The defaults usually just work:

| Var | Default | What it does |
|---|---|---|
| `HEIDRUN_SPIRIT_HOST` | _(required)_ | Hotline server hostname or IP |
| `HEIDRUN_SPIRIT_PORT` | `5500` (TLS: `5503`) | TCP port |
| `HEIDRUN_SPIRIT_LOGIN` | `""` (guest) | Account login |
| `HEIDRUN_SPIRIT_PASSWORD` | `""` | Account password |
| `HEIDRUN_SPIRIT_NICK` | `Heidrun's Spirit` | Display name |
| `HEIDRUN_SPIRIT_ICON` | `0` | Hotline numeric icon ID |
| `HEIDRUN_SPIRIT_EMOJI` | _(unset)_ | Emoji avatar (Heidrun servers only) |
| `HEIDRUN_SPIRIT_TLS` | `false` | `true` / `1` enables TLS (system trust) |
| `HEIDRUN_SPIRIT_BRAIN_PATH` | _(tempdir)_ | Where the brain is written |
| `HEIDRUN_SPIRIT_AUTOSAVE` | `25` | Save the brain every N replies |
| `HEIDRUN_SPIRIT_LOG_LEVEL` | `info` | `debug` / `info` / `error` |

## Co-locating with heidrun-server

If you're already running [heidrun-server](https://github.com/franckjej/heidrun-server) on the same Docker host, uncomment the `networks:` stanzas in `docker-compose.yml` and set `HEIDRUN_SPIRIT_HOST: heidrun-server`. The bot joins heidrun-server's compose network and dials it by service name.

## Architecture

```
heidrun-spirit (executable)        connect/reconnect loop + signals
        │
        ▼
SpiritBot     (SpiritKit)          chatter / self-filter / autosave
   ├─ MegaHALBrain (actor)         wraps the C engine; one shared instance
   │     └─ CMegaHAL (C target)    1998 MegaHAL, compiled with -std=gnu89 -w
   └─ ChatLineParser               splits "<nick>: <body>" lines from the wire
```

MegaHAL is process-global C state — there's exactly **one** brain actor per process, and any test suite that touches it must be `.serialized`.

## License

GPL-2.0 (the bundled MegaHAL C is GPL-2.0). Full text in [`LICENSE`](LICENSE).

### Dual licensing

Copyright © Daubit & Francke GmbH for the Swift wrapper. The MegaHAL C (© 1998 Jason Hutchens) is unmodified GPL-2.0. The Swift code shares the GPL-2.0 grant by necessity since it links against GPL'd C; this also keeps the bot under the same posture as the rest of the Heidrun trio.

For a non-GPL licence on the Swift wrapper: `jens.francke@daubit-francke.de`.

### Third-party

Built on:

- [MegaHAL](https://megahal.alioth.debian.org/) — © 1998 Jason Hutchens, GPL-2.0 (bundled verbatim under `Sources/CMegaHAL/`)
- [heidrun-protocol](https://github.com/franckjej/heidrun-protocol) — `HeidrunCore` + `HeidrunNIOClient`, GPL-2.0
- [swift-nio](https://github.com/apple/swift-nio), [swift-log](https://github.com/apple/swift-log) — Apache 2.0

## Heritage

The original *Heidrun's Spirit* was a 2002 Objective-C plug-in for the Heidrun Mac client by Göran Granström. This is a Swift revival on a modern transport — same Markov-chatter mischief, runs anywhere now.
